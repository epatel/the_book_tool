import 'package:the_book_tool/index.dart';

class AIService {
  static const String _keyApiKey = 'openai_api_key';
  OpenAIClient? _client;

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    _client = null; // Reset client to use new API key
  }

  Future<OpenAIClient?> _getClient() async {
    if (_client != null) return _client;

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    _client = OpenAIClient(apiKey: apiKey);
    return _client;
  }

  Future<String?> sendPrompt({
    required String prompt,
    required Map<String, dynamic> context,
  }) async {
    final client = await _getClient();
    if (client == null) {
      return null;
    }

    try {
      final itemType = context['currentItem']['type'];
      final currentText =
          context['currentItem']['content'] ??
          context['currentItem']['description'] ??
          '';

      final systemMessage =
          '''
You are an AI writing assistant helping an author with their book.
You have access to the complete book context including all chapters, characters, plots, and misc notes.

The author is currently editing a $itemType.
Full book context: ${context['bookData']}

IMPORTANT: Your response should be ONLY the updated text for this $itemType.
Do not include any explanations, suggestions, or commentary.
Just return the improved/updated text that should replace the current content.

Current text:
$currentText
''';

      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId('gpt-4.1'),
          messages: [
            ChatCompletionMessage.system(content: systemMessage),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
          // GPT-5 optimized parameters for creative writing
          maxCompletionTokens: 4096, // Allow longer creative responses
        ),
      );

      final content = response.choices.first.message.content;
      return content;
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return null;
    }
  }
}
