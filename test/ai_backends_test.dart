import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_book_tool/index.dart';

/// Spins up a throwaway HTTP server and hands each request to [handle].
///
/// The backends build their own http.Client, so the seam for testing them is
/// the base URL rather than an injected client.
Future<HttpServer> _serve(
  Future<void> Function(HttpRequest request) handle,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    await handle(request);
    await request.response.close();
  });
  return server;
}

void _json(HttpRequest request, int status, Object body) {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
}

void main() {
  group('AnthropicBackend', () {
    test('sends the documented request shape', () async {
      Map<String, dynamic>? received;
      String? apiKeyHeader;
      String? versionHeader;

      final server = await _serve((request) async {
        apiKeyHeader = request.headers.value('x-api-key');
        versionHeader = request.headers.value('anthropic-version');
        received = jsonDecode(await utf8.decoder.bind(request).join());
        _json(request, 200, {
          'model': 'claude-opus-5',
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': 'Once upon a time.'},
          ],
          'usage': {'input_tokens': 120, 'output_tokens': 8},
        });
      });
      addTearDown(server.close);

      final backend = AnthropicBackend(
        apiKey: 'sk-ant-test',
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      final result = await backend.send(
        const AIBackendRequest(
          systemMessage: 'You are an assistant.',
          prompt: 'Write something.',
          model: 'claude-opus-5',
          maxTokens: 1234,
        ),
      );

      expect(apiKeyHeader, 'sk-ant-test');
      expect(versionHeader, AnthropicBackend.apiVersion);
      expect(received!['model'], 'claude-opus-5');
      expect(received!['max_tokens'], 1234);
      expect(received!['system'], 'You are an assistant.');
      expect(received!['messages'], [
        {'role': 'user', 'content': 'Write something.'},
      ]);

      expect(result.content, 'Once upon a time.');
      expect(result.promptTokens, 120);
      expect(result.completionTokens, 8);
      expect(result.totalTokens, 128);
      expect(result.model, 'claude-opus-5');
      expect(result.costUsd, isNull);
    });

    test('concatenates text blocks and skips thinking blocks', () async {
      final server = await _serve((request) async {
        _json(request, 200, {
          'model': 'claude-opus-5',
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'thinking', 'thinking': ''},
            {'type': 'text', 'text': 'First. '},
            {'type': 'text', 'text': 'Second.'},
          ],
          'usage': {'input_tokens': 1, 'output_tokens': 2},
        });
      });
      addTearDown(server.close);

      final backend = AnthropicBackend(
        apiKey: 'k',
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      final result = await backend.send(
        const AIBackendRequest(
          systemMessage: 's',
          prompt: 'p',
          model: 'claude-opus-5',
        ),
      );
      expect(result.content, 'First. Second.');
    });

    test('surfaces a refusal as an exception, not empty text', () async {
      final server = await _serve((request) async {
        _json(request, 200, {
          'model': 'claude-opus-5',
          'stop_reason': 'refusal',
          'stop_details': {'type': 'refusal', 'explanation': 'nope'},
          'content': <dynamic>[],
        });
      });
      addTearDown(server.close);

      final backend = AnthropicBackend(
        apiKey: 'k',
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      expect(
        () => backend.send(
          const AIBackendRequest(
            systemMessage: 's',
            prompt: 'p',
            model: 'claude-opus-5',
          ),
        ),
        throwsA(
          isA<AIBackendException>().having(
            (e) => e.message,
            'message',
            contains('nope'),
          ),
        ),
      );
    });

    test('reports the API error message on a non-200', () async {
      final server = await _serve((request) async {
        _json(request, 401, {
          'type': 'error',
          'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'},
        });
      });
      addTearDown(server.close);

      final backend = AnthropicBackend(
        apiKey: 'bad',
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      expect(
        () => backend.send(
          const AIBackendRequest(
            systemMessage: 's',
            prompt: 'p',
            model: 'claude-opus-5',
          ),
        ),
        throwsA(
          isA<AIBackendException>().having(
            (e) => e.message,
            'message',
            contains('invalid x-api-key'),
          ),
        ),
      );
    });

    test('fails fast without an API key', () async {
      final backend = AnthropicBackend(apiKey: '', baseUrl: 'http://127.0.0.1:1');
      addTearDown(backend.dispose);

      expect(
        () => backend.send(
          const AIBackendRequest(
            systemMessage: 's',
            prompt: 'p',
            model: 'claude-opus-5',
          ),
        ),
        throwsA(isA<AIBackendException>()),
      );
      expect((await backend.check()).ok, isFalse);
    });
  });

  group('SidecarBackend', () {
    test('round-trips a completion and trusts its reported cost', () async {
      Map<String, dynamic>? received;

      final server = await _serve((request) async {
        received = jsonDecode(await utf8.decoder.bind(request).join());
        _json(request, 200, {
          'text': '  Drafted.  ',
          'model': 'claude-opus-5',
          'usage': {'input_tokens': 50, 'output_tokens': 10},
          'cost_usd': 0.0,
        });
      });
      addTearDown(server.close);

      final backend = SidecarBackend(
        baseUrl: 'http://127.0.0.1:${server.port}',
        provider: 'claude-agent-sdk',
      );
      addTearDown(backend.dispose);

      final result = await backend.send(
        const AIBackendRequest(
          systemMessage: 'sys',
          prompt: 'go',
          model: 'claude-opus-5',
        ),
      );

      expect(received!['provider'], 'claude-agent-sdk');
      expect(received!['system'], 'sys');
      expect(received!['prompt'], 'go');
      expect(result.content, 'Drafted.');
      // 0.0 from a subscription-backed run must survive as 0.0, not null.
      expect(result.costUsd, 0.0);
      expect(result.totalTokens, 60);
    });

    test('advertised providers and models come back from /health', () async {
      final server = await _serve((request) async {
        _json(request, 200, {
          'status': 'ok',
          'providers': {
            'claude-agent-sdk': {
              'models': ['claude-opus-5', 'claude-sonnet-5'],
            },
            'litellm': {'models': <String>[]},
          },
        });
      });
      addTearDown(server.close);

      final backend = SidecarBackend(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      final health = await backend.check();
      expect(health.ok, isTrue);
      expect(health.message, contains('claude-agent-sdk'));
      expect(health.models, ['claude-opus-5', 'claude-sonnet-5']);

      expect(await backend.listProviders(), {
        'claude-agent-sdk': ['claude-opus-5', 'claude-sonnet-5'],
        'litellm': <String>[],
      });
    });

    test('a sidecar with no providers reports why, not "Connected"', () async {
      // Reachable but serving nothing: every completion would return 503,
      // so Test must not claim success.
      final server = await _serve((request) async {
        _json(request, 200, {
          'status': 'ok',
          'providers': <String, dynamic>{},
          'unavailable': {
            'claude-agent-sdk': 'not installed (pip install claude-agent-sdk)',
            'anthropic': 'ANTHROPIC_API_KEY is not set',
          },
        });
      });
      addTearDown(server.close);

      final backend = SidecarBackend(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      final health = await backend.check();
      expect(health.ok, isFalse);
      expect(health.message, contains('no providers available'));
      expect(health.message, contains('pip install claude-agent-sdk'));
      expect(health.message, contains('ANTHROPIC_API_KEY is not set'));
    });

    test('surfaces the 503 body when no provider can serve', () async {
      final server = await _serve((request) async {
        _json(request, 503, {
          'error': 'No providers available. anthropic: ANTHROPIC_API_KEY is not set',
        });
      });
      addTearDown(server.close);

      final backend = SidecarBackend(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      addTearDown(backend.dispose);

      expect(
        () => backend.send(
          const AIBackendRequest(
            systemMessage: 's',
            prompt: 'p',
            model: 'm',
          ),
        ),
        throwsA(
          isA<AIBackendException>().having(
            (e) => e.message,
            'message',
            contains('ANTHROPIC_API_KEY is not set'),
          ),
        ),
      );
    });

    test('sends a bearer token when one is configured', () async {
      String? auth;
      final server = await _serve((request) async {
        auth = request.headers.value('authorization');
        _json(request, 200, {
          'status': 'ok',
          'providers': {
            'anthropic': {'models': <String>['claude-opus-5']},
          },
        });
      });
      addTearDown(server.close);

      final backend = SidecarBackend(
        baseUrl: 'http://127.0.0.1:${server.port}',
        token: 't0k',
      );
      addTearDown(backend.dispose);

      await backend.check();
      expect(auth, 'Bearer t0k');
    });

    test('an unreachable sidecar reports down rather than throwing', () async {
      // Bind then immediately release, so the port is almost certainly dead.
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();

      final backend = SidecarBackend(baseUrl: 'http://127.0.0.1:$port');
      addTearDown(backend.dispose);

      final health = await backend.check();
      expect(health.ok, isFalse);
      expect(health.message, contains('Not running'));

      expect(
        () => backend.send(
          const AIBackendRequest(
            systemMessage: 's',
            prompt: 'p',
            model: 'm',
          ),
        ),
        throwsA(
          isA<AIBackendException>().having(
            (e) => e.message,
            'message',
            contains('Is it running?'),
          ),
        ),
      );
    });
  });

  group('AIResponse cost', () {
    test('a backend-reported cost wins over the pricing table', () {
      const response = AIResponse(
        text: 'x',
        promptTokens: 1000000,
        completionTokens: 1000000,
        model: 'claude-opus-5',
        costUsd: 0.0,
      );
      expect(response.estimatedCost, 0.0);
    });

    test('falls back to the pricing table when no cost is reported', () {
      const response = AIResponse(
        text: 'x',
        promptTokens: 1000000,
        completionTokens: 1000000,
        model: 'claude-opus-5',
      );
      // Claude Opus 5: $5/MTok in, $25/MTok out.
      expect(response.estimatedCost, closeTo(30.0, 0.0001));
    });
  });

  group('backend configuration defaults', () {
    test('each backend has its own storage keys, URL and model', () {
      final urls = AIBackendKind.values.map(defaultUrlForBackend).toSet();
      final keys = AIBackendKind.values.map((k) => k.secureStorageKey).toSet();
      final modelKeys = AIBackendKind.values.map((k) => k.modelManifestKey).toSet();
      final urlKeys = AIBackendKind.values.map((k) => k.urlManifestKey).toSet();

      expect(urls.length, AIBackendKind.values.length);
      expect(keys.length, AIBackendKind.values.length);
      expect(modelKeys.length, AIBackendKind.values.length);
      expect(urlKeys.length, AIBackendKind.values.length);
    });

    test('existing books keep their OpenAI settings', () {
      // Backward compatibility: no stored AIBackend means the old behaviour.
      expect(AIBackendKind.fromString(null), AIBackendKind.openAiCompatible);
      expect(AIBackendKind.fromString('nonsense'), AIBackendKind.openAiCompatible);
      expect(
        AIBackendKind.openAiCompatible.modelManifestKey,
        'AIModel',
      );
      expect(AIBackendKind.openAiCompatible.urlManifestKey, 'AIApiUrl');
      expect(AIBackendKind.openAiCompatible.secureStorageKey, 'openai_api_key');
    });

    test('only the sidecar works without an API key', () {
      expect(AIBackendKind.sidecar.usesApiKey, isFalse);
      expect(AIBackendKind.anthropic.usesApiKey, isTrue);
      expect(AIBackendKind.openAiCompatible.usesApiKey, isTrue);
    });

    test('Claude models are priced', () {
      for (final model in anthropicModelPresets) {
        expect(modelPricing[model], isNotNull, reason: '$model has no pricing');
      }
    });
  });
}
