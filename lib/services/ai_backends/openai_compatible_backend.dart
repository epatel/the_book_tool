import 'package:the_book_tool/index.dart';

/// OpenAI and anything that speaks its chat-completions API.
///
/// This is the backend the app shipped with; behaviour is unchanged.
class OpenAICompatibleBackend implements AIBackend {
  final String apiKey;
  final String baseUrl;

  OpenAIClient? _client;

  OpenAICompatibleBackend({required this.apiKey, required this.baseUrl});

  @override
  AIBackendKind get kind => AIBackendKind.openAiCompatible;

  OpenAIClient get _openAi =>
      _client ??= OpenAIClient(apiKey: apiKey, baseUrl: baseUrl);

  @override
  Future<AIBackendResult> send(AIBackendRequest request) async {
    if (apiKey.isEmpty) {
      throw const AIBackendException('No API key set for the OpenAI backend.');
    }

    final response = await _openAi.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(request.model),
        messages: [
          ChatCompletionMessage.system(content: request.systemMessage),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(request.prompt),
          ),
        ],
        maxCompletionTokens: request.maxTokens,
      ),
    );

    final content = response.choices.first.message.content;
    if (content == null || content.isEmpty) {
      throw const AIBackendException('The model returned an empty response.');
    }

    final usage = response.usage;
    return AIBackendResult(
      content: content,
      promptTokens: usage?.promptTokens,
      completionTokens: usage?.completionTokens,
      totalTokens: usage?.totalTokens,
      model: response.model,
    );
  }

  @override
  Future<AIBackendHealth> check() async {
    if (apiKey.isEmpty) {
      return const AIBackendHealth(ok: false, message: 'No API key set.');
    }

    try {
      final models = await _openAi.listModels();
      final ids = models.data.map((model) => model.id).toList()..sort();
      return AIBackendHealth(
        ok: true,
        message: 'Connected · ${ids.length} models available',
        models: ids,
      );
    } catch (e) {
      // Not every OpenAI-compatible host implements /models; a failure here
      // does not necessarily mean completions are broken.
      return AIBackendHealth(
        ok: false,
        message: 'Could not list models: ${_short(e)}',
      );
    }
  }

  @override
  void dispose() {
    _client?.endSession();
    _client = null;
  }

  String _short(Object error) {
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 160)}...' : text;
  }
}
