import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_book_tool/index.dart';

/// Claude models called directly on the Anthropic Messages API.
///
/// There is no official Anthropic SDK for Dart, so this speaks raw HTTPS.
/// Requests are non-streaming: the app shows a spinner and swaps in the whole
/// response, which is what every edit dialog already expects.
class AnthropicBackend implements AIBackend {
  /// Wire format version. Pinned deliberately — bumping it is a breaking change.
  static const String apiVersion = '2023-06-01';

  final String apiKey;
  final String baseUrl;

  http.Client? _client;

  AnthropicBackend({required this.apiKey, required this.baseUrl});

  @override
  AIBackendKind get kind => AIBackendKind.anthropic;

  http.Client get _http => _client ??= http.Client();

  Map<String, String> get _headers => {
    'x-api-key': apiKey,
    'anthropic-version': apiVersion,
    'content-type': 'application/json',
  };

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }

  @override
  Future<AIBackendResult> send(AIBackendRequest request) async {
    if (apiKey.isEmpty) {
      throw const AIBackendException(
        'No API key set for the Anthropic backend.',
      );
    }

    final response = await _http.post(
      _uri('/messages'),
      headers: _headers,
      body: jsonEncode({
        'model': request.model,
        'max_tokens': request.maxTokens,
        'system': request.systemMessage,
        'messages': [
          {'role': 'user', 'content': request.prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AIBackendException(_errorMessage(response));
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const AIBackendException('Unexpected response from Anthropic.');
    }

    // Safety classifiers can decline a request with HTTP 200.
    if (body['stop_reason'] == 'refusal') {
      final details = body['stop_details'];
      final explanation = details is Map<String, dynamic>
          ? (details['explanation'] as String?)
          : null;
      throw AIBackendException(
        'Claude declined this request${explanation == null ? '.' : ': $explanation'}',
      );
    }

    final content = _extractText(body['content']);
    if (content.isEmpty) {
      throw const AIBackendException('The model returned an empty response.');
    }

    final usage = body['usage'];
    final inputTokens = usage is Map<String, dynamic>
        ? usage['input_tokens'] as int?
        : null;
    final outputTokens = usage is Map<String, dynamic>
        ? usage['output_tokens'] as int?
        : null;

    return AIBackendResult(
      content: content,
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: (inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null,
      model: body['model'] as String? ?? request.model,
    );
  }

  /// Joins the text blocks of a response, skipping thinking and tool blocks.
  String _extractText(dynamic content) {
    if (content is! List) return '';

    final buffer = StringBuffer();
    for (final block in content) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        buffer.write(block['text'] as String? ?? '');
      }
    }
    return buffer.toString().trim();
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          return 'Anthropic ${response.statusCode}: ${error['message']}';
        }
      }
    } catch (_) {
      // Fall through to the status-only message.
    }
    return 'Anthropic request failed with HTTP ${response.statusCode}.';
  }

  @override
  Future<AIBackendHealth> check() async {
    if (apiKey.isEmpty) {
      return const AIBackendHealth(ok: false, message: 'No API key set.');
    }

    try {
      final response = await _http.get(_uri('/models'), headers: _headers);
      if (response.statusCode != 200) {
        return AIBackendHealth(ok: false, message: _errorMessage(response));
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = body is Map<String, dynamic> ? body['data'] : null;
      final ids = data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map((model) => model['id'] as String? ?? '')
                .where((id) => id.isNotEmpty)
                .toList()
          : <String>[];

      return AIBackendHealth(
        ok: true,
        message: 'Connected · ${ids.length} models available',
        models: ids,
      );
    } catch (e) {
      return AIBackendHealth(ok: false, message: 'Could not reach Anthropic: $e');
    }
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}
