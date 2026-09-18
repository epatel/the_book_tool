import 'package:the_book_tool/index.dart';

class AIService {
  static final _secureStorage = const FlutterSecureStorage();

  AIBackend? _backend;

  /// Identity of the config [_backend] was built from, so we can tell when a
  /// settings change invalidates it.
  String? _backendSignature;

  /// Which backend the current book is configured to use.
  Future<AIBackendKind> getBackendKind() async {
    final manifestRepo = ManifestRepository();
    return AIBackendKind.fromString(
      (await manifestRepo.get('AIBackend'))?.value,
    );
  }

  /// Read the stored credential for [kind], defaulting to the active backend.
  Future<String?> getApiKey([AIBackendKind? kind]) async {
    final target = kind ?? await getBackendKind();
    return await _secureStorage.read(key: target.secureStorageKey);
  }

  /// Store (or clear, when [apiKey] is empty) the credential for [kind].
  Future<void> setApiKey(String apiKey, [AIBackendKind? kind]) async {
    final target = kind ?? await getBackendKind();
    if (apiKey.isEmpty) {
      await _secureStorage.delete(key: target.secureStorageKey);
    } else {
      await _secureStorage.write(key: target.secureStorageKey, value: apiKey);
    }
    invalidateBackend();
  }

  /// Whether AI features should be offered.
  ///
  /// Not the same as "has an API key": the sidecar backend authenticates
  /// itself, so being pointed at one is enough.
  Future<bool> isConfigured() async {
    final kind = await getBackendKind();
    if (!kind.usesApiKey) return true;

    final apiKey = await getApiKey(kind);
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Drop the cached backend so the next call rebuilds it from settings.
  void invalidateBackend() {
    _backend?.dispose();
    _backend = null;
    _backendSignature = null;
  }

  /// Build a backend from explicit values, without touching stored settings.
  /// Used by the settings dialog to test a configuration before saving it.
  static AIBackend buildBackend({
    required AIBackendKind kind,
    required String apiKey,
    required String baseUrl,
    String sidecarProvider = '',
  }) {
    return switch (kind) {
      AIBackendKind.openAiCompatible => OpenAICompatibleBackend(
        apiKey: apiKey,
        baseUrl: baseUrl.isEmpty ? defaultApiUrl : baseUrl,
      ),
      AIBackendKind.anthropic => AnthropicBackend(
        apiKey: apiKey,
        baseUrl: baseUrl.isEmpty ? defaultAnthropicApiUrl : baseUrl,
      ),
      AIBackendKind.sidecar => SidecarBackend(
        baseUrl: baseUrl.isEmpty ? defaultSidecarUrl : baseUrl,
        token: apiKey,
        provider: sidecarProvider,
      ),
    };
  }

  Future<AIBackend?> _getBackend() async {
    final kind = await getBackendKind();
    if (!await isConfigured()) return null;

    final manifestRepo = ManifestRepository();
    final apiKey = await getApiKey(kind) ?? '';
    final baseUrl =
        (await manifestRepo.get(kind.urlManifestKey))?.value ??
        defaultUrlForBackend(kind);
    final sidecarProvider =
        (await manifestRepo.get('AISidecarProvider'))?.value ??
        defaultSidecarProvider;

    final signature = '${kind.name}|$baseUrl|$sidecarProvider|${apiKey.hashCode}';
    if (_backend != null && _backendSignature == signature) {
      return _backend;
    }

    _backend?.dispose();
    _backendSignature = signature;
    _backend = buildBackend(
      kind: kind,
      apiKey: apiKey,
      baseUrl: baseUrl,
      sidecarProvider: sidecarProvider,
    );
    return _backend;
  }

  /// Resolve the model to use for the active backend.
  Future<String> getActiveModel() async {
    final kind = await getBackendKind();
    final manifestRepo = ManifestRepository();
    final stored = (await manifestRepo.get(kind.modelManifestKey))?.value;
    return (stored == null || stored.isEmpty)
        ? defaultModelForBackend(kind)
        : stored;
  }

  Future<AIResponse?> sendPrompt({
    required String prompt,
    Map<String, dynamic>? context,
    AIUsageProvider? usageProvider,
    String? contextType,
    int? contextId,
    String? contextName,
  }) async {
    final backend = await _getBackend();
    if (backend == null) {
      return null;
    }

    try {
      // Get context prompt and AI model from manifest
      final manifestRepo = ManifestRepository();
      final contextPrompt =
          (await manifestRepo.get('ContextPrompt'))?.value ?? '';
      final aiModel = await getActiveModel();

      final enableCommands = context?['enableCommands'] == true;
      final hasCurrentItem = context?['currentItem'] != null;

      String systemMessage;

      if (!hasCurrentItem) {
        // Book-level prompt (no specific item being edited)
        systemMessage = _buildBookLevelSystemMessage(
          context?['bookData'],
          contextPrompt,
          enableCommands,
        );
      } else {
        // Item-level prompt (editing a specific item)
        final itemType = context!['currentItem']['type'];
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

        systemMessage = enableCommands
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
      }

      final result = await backend.send(
        AIBackendRequest(
          systemMessage: systemMessage,
          prompt: prompt,
          model: aiModel,
          maxTokens: aiMaxOutputTokens,
        ),
      );

      final content = result.content;
      if (content.isEmpty) {
        return null;
      }

      // Extract usage information
      final promptTokens = result.promptTokens;
      final completionTokens = result.completionTokens;
      final totalTokens = result.totalTokens;
      final modelUsed = result.model;
      final costUsd = result.costUsd;

      // Update cumulative token usage in manifest
      if (promptTokens != null &&
          completionTokens != null &&
          totalTokens != null) {
        await _updateTokenUsage(
          promptTokens,
          completionTokens,
          totalTokens,
          usageProvider,
        );
      }

      // Log to prompt history if context provided
      if (contextType != null && contextName != null) {
        await _logPromptHistory(
          prompt: prompt,
          response: content,
          contextType: contextType,
          contextId: contextId,
          contextName: contextName,
          wasCommand: enableCommands,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: totalTokens,
          model: modelUsed,
        );
      }

      // Parse response for commands if enabled
      if (enableCommands) {
        final commands = AICommand.parseFromResponse(content);
        if (commands.isNotEmpty) {
          // If we have commands, return them without text
          return AIResponse(
            commands: commands,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
            model: modelUsed,
            costUsd: costUsd,
          );
        }
      }

      // Return text response (for non-command mode or if no commands found)
      return AIResponse(
        text: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        model: modelUsed,
        costUsd: costUsd,
      );
    } on AIBackendException catch (e) {
      debugPrint('AI Backend Error: ${e.message}');
      return null;
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

  String _buildBookLevelSystemMessage(
    dynamic bookData,
    String contextPrompt,
    bool enableCommands,
  ) {
    if (enableCommands) {
      return '''
You are an AI writing assistant helping an author with their book.
You have access to the complete book context including all chapters, characters, plots, and misc notes.${contextPrompt.isNotEmpty ? '\n\nAdditional Context: $contextPrompt' : ''}

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
    } else {
      return '''
You are an AI writing assistant helping an author with their book.
You have access to the complete book context including all chapters, characters, plots, and misc notes.${contextPrompt.isNotEmpty ? '\n\nAdditional Context: $contextPrompt' : ''}

Full book context: $bookData

The author is asking a general question about their book. Provide helpful, detailed answers based on the book's content.
Be conversational and thorough in your response.
''';
    }
  }

  Future<void> _updateTokenUsage(
    int promptTokens,
    int completionTokens,
    int totalTokens,
    AIUsageProvider? usageProvider,
  ) async {
    try {
      final manifestRepo = ManifestRepository();

      // Get current cumulative values
      final currentPromptTokens =
          int.tryParse(
            (await manifestRepo.get('TotalPromptTokens'))?.value ?? '0',
          ) ??
          0;
      final currentCompletionTokens =
          int.tryParse(
            (await manifestRepo.get('TotalCompletionTokens'))?.value ?? '0',
          ) ??
          0;
      final currentTotalTokens =
          int.tryParse(
            (await manifestRepo.get('TotalTokens'))?.value ?? '0',
          ) ??
          0;

      // Add new usage to cumulative values
      final newPromptTokens = currentPromptTokens + promptTokens;
      final newCompletionTokens = currentCompletionTokens + completionTokens;
      final newTotalTokens = currentTotalTokens + totalTokens;

      // Update manifest
      await manifestRepo.setMultiple({
        'TotalPromptTokens': newPromptTokens.toString(),
        'TotalCompletionTokens': newCompletionTokens.toString(),
        'TotalTokens': newTotalTokens.toString(),
      });

      // Notify provider if available
      if (usageProvider != null) {
        await usageProvider.updateUsage(
          promptTokens,
          completionTokens,
          totalTokens,
        );
      }

      debugPrint(
        'Updated token usage: +$promptTokens/$completionTokens (total: $newTotalTokens)',
      );
    } catch (e) {
      debugPrint('Error updating token usage: $e');
    }
  }

  String _generateResponseSummary({
    required String response,
    required bool wasCommand,
    required String contextType,
    required String contextName,
  }) {
    // For command responses, parse and summarize the commands
    if (wasCommand) {
      try {
        final commands = AICommand.parseFromResponse(response);
        if (commands.isEmpty) {
          return 'Command executed';
        }

        // Group commands by type
        final chapters = <String>[];
        final characters = <String>[];
        final plots = <String>[];
        final notes = <String>[];

        for (final command in commands) {
          if (command is AddChapterCommand) {
            chapters.add(command.title);
          } else if (command is AddCharacterCommand) {
            characters.add(command.name);
          } else if (command is AddPlotCommand) {
            plots.add(command.title);
          } else if (command is AddMiscNoteCommand) {
            notes.add(command.title);
          }
        }

        // Build summary
        final parts = <String>[];
        if (chapters.isNotEmpty) {
          parts.add('Chapters: ${chapters.join(', ')}');
        }
        if (characters.isNotEmpty) {
          parts.add('Characters: ${characters.join(', ')}');
        }
        if (plots.isNotEmpty) {
          parts.add('Plots: ${plots.join(', ')}');
        }
        if (notes.isNotEmpty) {
          parts.add('Notes: ${notes.join(', ')}');
        }

        return 'Created ${parts.join('; ')}';
      } catch (e) {
        return 'Command executed';
      }
    }

    // For regular responses, show context type, name, and first ~5 words
    final words = response.split(RegExp(r'\s+'));
    final preview = words.take(5).join(' ');
    final suffix = words.length > 5 ? '...' : '';

    return '$contextType: $contextName, $preview$suffix';
  }

  Future<void> _logPromptHistory({
    required String prompt,
    required String response,
    required String contextType,
    int? contextId,
    required String contextName,
    required bool wasCommand,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? model,
  }) async {
    try {
      // Generate summary instead of storing full response
      final summary = _generateResponseSummary(
        response: response,
        wasCommand: wasCommand,
        contextType: contextType,
        contextName: contextName,
      );

      final historyRepo = PromptHistoryRepository();
      final history = PromptHistory(
        promptText: prompt,
        responseText: summary,
        contextType: contextType,
        contextId: contextId,
        contextName: contextName,
        wasCommand: wasCommand,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        model: model,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await historyRepo.insert(history);
      debugPrint('Logged prompt history for $contextType: $contextName');
    } catch (e) {
      debugPrint('Error logging prompt history: $e');
    }
  }
}
