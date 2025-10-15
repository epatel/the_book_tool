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

  Future<AIResponse?> sendPrompt({
    required String prompt,
    required Map<String, dynamic> context,
  }) async {
    final client = await _getClient();
    if (client == null) {
      return null;
    }

    try {
      // Get context prompt from manifest
      final manifestRepo = ManifestRepository();
      final contextPrompt =
          (await manifestRepo.get('ContextPrompt'))?.value ?? '';

      final enableCommands = context['enableCommands'] == true;
      final itemType = context['currentItem']['type'];
      final currentText =
          context['currentItem']['content'] ??
          context['currentItem']['description'] ??
          '';

      final cursorInfo = !enableCommands
          ? {
              'cursorPosition': context['currentItem']['cursorPosition'],
              'selectedText': context['currentItem']['selectedText'],
              'textBeforeCursor': context['currentItem']['textBeforeCursor'],
              'textAfterCursor': context['currentItem']['textAfterCursor'],
            }
          : null;

      final systemMessage = enableCommands
          ? _buildCommandSystemMessage(
              itemType,
              context['bookData'],
              contextPrompt,
            )
          : _buildDefaultSystemMessage(
              itemType,
              context['bookData'],
              currentText,
              cursorInfo,
              contextPrompt,
            );

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
      if (content == null || content.isEmpty) {
        return null;
      }

      // Parse response for commands if enabled
      if (enableCommands) {
        final commands = AICommand.parseFromResponse(content);
        if (commands.isNotEmpty) {
          // If we have commands, return them without text
          return AIResponse(commands: commands);
        }
      }

      // Return text response (for non-command mode or if no commands found)
      return AIResponse(text: content);
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return null;
    }
  }

  String _buildDefaultSystemMessage(
    String itemType,
    dynamic bookData,
    String currentText,
    Map<String, dynamic>? cursorInfo,
    String contextPrompt,
  ) {
    final selectedText = cursorInfo?['selectedText'] ?? '';
    final textBefore = cursorInfo?['textBeforeCursor'] ?? '';
    final textAfter = cursorInfo?['textAfterCursor'] ?? '';
    final hasSelection = selectedText.isNotEmpty;

    return '''
You are an AI writing assistant helping an author with their book.
You have access to the complete book context including all chapters, characters, plots, and misc notes.${contextPrompt.isNotEmpty ? '\n\nAdditional Context: $contextPrompt' : ''}

The author is currently editing a $itemType.
Full book context: $bookData

IMPORTANT EDITING BEHAVIOR:
- Your response will be ${hasSelection ? 'REPLACING the selected text' : 'inserted at the cursor position'}
- Do NOT return the entire content - only provide the text to ${hasSelection ? 'replace the selection' : 'insert'}
- Do not include explanations or commentary - just the text to ${hasSelection ? 'replace with' : 'insert'}

Full current text:
$currentText

${hasSelection ? '''
SELECTED TEXT (will be replaced by your response):
$selectedText
''' : ''}
CONTEXT - Text before cursor:
${textBefore.isEmpty
        ? '(beginning of text)'
        : textBefore.length > 200
        ? '...${textBefore.substring(textBefore.length - 200)}'
        : textBefore}

CONTEXT - Text after cursor:
${textAfter.isEmpty
        ? '(end of text)'
        : textAfter.length > 200
        ? '${textAfter.substring(0, 200)}...'
        : textAfter}
''';
  }

  String _buildCommandSystemMessage(
    String itemType,
    dynamic bookData,
    String contextPrompt,
  ) {
    return '''
You are an AI writing assistant helping an author with their book.
You have access to the complete book context including all chapters, characters, plots, and misc notes.${contextPrompt.isNotEmpty ? '\n\nAdditional Context: $contextPrompt' : ''}

The author is currently editing a $itemType.
Full book context: $bookData

You can create new book items by responding with JSON commands in markdown code blocks.

Supported commands:
- add_chapter: {"action": "add_chapter", "data": {"title": "...", "content": "..."}}
- add_character: {"action": "add_character", "data": {"name": "...", "description": "..."}}
- add_plot: {"action": "add_plot", "data": {"title": "...", "description": "..."}}
- add_misc_note: {"action": "add_misc_note", "data": {"title": "...", "content": "..."}}

For multiple commands, use a JSON array:
```json
[
  {"action": "add_chapter", "data": {"title": "Chapter 1", "content": "..."}},
  {"action": "add_character", "data": {"name": "Hero", "description": "..."}}
]
```

IMPORTANT:
- Wrap JSON in markdown code blocks with ```json
- ONLY return JSON commands, no other text or explanations
- Ensure all required fields are present (title/name, content/description)
- Create meaningful, complete content for each item
''';
  }
}
