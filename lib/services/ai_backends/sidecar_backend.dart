import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_book_tool/index.dart';

/// A local Python process that fronts whatever providers it wants.
///
/// The app never starts this process: the macOS build is sandboxed and cannot
/// launch an external interpreter. The user runs `sidecar/book_tool_sidecar.py`
/// themselves and the app connects over loopback (allowed by the
/// `com.apple.security.network.client` entitlement).
///
/// Protocol (see sidecar/README.md for the reference implementation):
///
///   GET  /health        -> {"status": "ok", "providers": {...}}
///   POST /v1/complete   -> {"text": ..., "usage": {...}, "cost_usd": ...}
class SidecarBackend implements AIBackend {
  final String baseUrl;

  /// Optional bearer token, if the user put one in front of their sidecar.
  final String token;

  /// Which provider the sidecar should route to (`claude-agent-sdk`,
  /// `anthropic`, `litellm`, ...). Empty means "whatever you default to".
  final String provider;

  http.Client? _client;

  SidecarBackend({
    required this.baseUrl,
    this.token = '',
    this.provider = '',
  });

  @override
  AIBackendKind get kind => AIBackendKind.sidecar;

  http.Client get _http => _client ??= http.Client();

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (token.isNotEmpty) 'authorization': 'Bearer $token',
  };

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }

  @override
  Future<AIBackendResult> send(AIBackendRequest request) async {
    final http.Response response;
    try {
      response = await _http.post(
        _uri('/v1/complete'),
        headers: _headers,
        body: jsonEncode({
          if (provider.isNotEmpty) 'provider': provider,
          'model': request.model,
          'system': request.systemMessage,
          'prompt': request.prompt,
          'max_tokens': request.maxTokens,
        }),
      );
    } catch (e) {
      throw AIBackendException(
        'Could not reach the sidecar at $baseUrl. Is it running? ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw AIBackendException(_errorMessage(response));
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const AIBackendException('Unexpected response from the sidecar.');
    }

    final text = (body['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw const AIBackendException('The sidecar returned an empty response.');
    }

    final usage = body['usage'];
    final inputTokens = usage is Map<String, dynamic>
        ? usage['input_tokens'] as int?
        : null;
    final outputTokens = usage is Map<String, dynamic>
        ? usage['output_tokens'] as int?
        : null;

    return AIBackendResult(
      content: text,
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: (inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null,
      model: body['model'] as String? ?? request.model,
      // The sidecar prices its own calls; a subscription-backed Agent SDK run
      // can legitimately report 0.0, which is different from "unknown".
      costUsd: (body['cost_usd'] as num?)?.toDouble(),
    );
  }

  @override
  Future<AIBackendHealth> check() async {
    try {
      final response = await _http.get(_uri('/health'), headers: _headers);
      if (response.statusCode != 200) {
        return AIBackendHealth(ok: false, message: _errorMessage(response));
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        return const AIBackendHealth(
          ok: false,
          message: 'Sidecar returned an unexpected payload.',
        );
      }

      final providers = body['providers'];
      final models = <String>[];
      final names = <String>[];

      if (providers is Map<String, dynamic>) {
        for (final entry in providers.entries) {
          names.add(entry.key);
          final value = entry.value;
          if (value is Map<String, dynamic> && value['models'] is List) {
            models.addAll(
              (value['models'] as List).whereType<String>(),
            );
          }
        }
      }

      // Reachable but serving nothing is a failure worth showing: every
      // completion would come back 503. Report why, from /health.
      if (names.isEmpty) {
        final blocked = body['unavailable'];
        final reasons = blocked is Map<String, dynamic>
            ? blocked.entries.map((e) => '${e.key}: ${e.value}').join('; ')
            : '';
        return AIBackendHealth(
          ok: false,
          message: reasons.isEmpty
              ? 'Running, but it has no providers available.'
              : 'Running, but no providers available — $reasons',
        );
      }

      return AIBackendHealth(
        ok: true,
        message: 'Connected · ${names.join(', ')}',
        models: models,
      );
    } catch (e) {
      return AIBackendHealth(
        ok: false,
        message: 'Not running at $baseUrl',
      );
    }
  }

  /// Providers the sidecar advertises, as `{name: [models]}`.
  Future<Map<String, List<String>>> listProviders() async {
    try {
      final response = await _http.get(_uri('/health'), headers: _headers);
      if (response.statusCode != 200) return {};

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final providers = body is Map<String, dynamic> ? body['providers'] : null;
      if (providers is! Map<String, dynamic>) return {};

      return {
        for (final entry in providers.entries)
          entry.key: entry.value is Map<String, dynamic>
              ? ((entry.value['models'] as List?)?.whereType<String>().toList() ??
                    <String>[])
              : <String>[],
      };
    } catch (_) {
      return {};
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['error'] != null) {
        return 'Sidecar ${response.statusCode}: ${body['error']}';
      }
    } catch (_) {
      // Fall through to the status-only message.
    }
    return 'Sidecar request failed with HTTP ${response.statusCode}.';
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}
