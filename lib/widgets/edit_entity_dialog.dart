import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Generic dialog for editing entities with AI assistance.
///
/// Supports chapters, characters, plots, and misc notes with configuration-based
/// behavior. Handles change tracking, delete confirmation, search highlighting,
/// and AI prompt integration.
class EditEntityDialog<T> extends StatefulWidget {
  final EditEntityDialogConfig config;
  final T entity;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;
  final String Function(T entity) getField1Value;
  final String Function(T entity) getField2Value;
  final int? Function(T entity)? getOrderIndex; // For chapter numbering
  final Future<void> Function(BuildContext context, T entity) onUpdate;
  final Future<void> Function(BuildContext context, int id) onDelete;
  final int Function(T entity) getId;
  final T Function(T entity, String field1, String field2) copyWith;

  const EditEntityDialog({
    super.key,
    required this.config,
    required this.entity,
    this.hasApiKey = false,
    this.searchQuery,
    this.searchLineNumber,
    required this.getField1Value,
    required this.getField2Value,
    this.getOrderIndex,
    required this.onUpdate,
    required this.onDelete,
    required this.getId,
    required this.copyWith,
  });

  @override
  State<EditEntityDialog<T>> createState() => _EditEntityDialogState<T>();
}

class _EditEntityDialogState<T> extends State<EditEntityDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  final UiPreferencesService _uiPrefs = UiPreferencesService();
  late final TextEditingController _field1Controller;
  late final TextEditingController _field2Controller;
  late final TextEditingController _aiPromptController;
  late final FocusNode _field2FocusNode;
  late final ScrollController _field2ScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  bool _enableCommands = false;
  bool _hasChanges = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;
  late String _originalField1;
  late String _originalField2;

  @override
  void initState() {
    super.initState();
    _originalField1 = widget.getField1Value(widget.entity);
    _originalField2 = widget.getField2Value(widget.entity);

    _field1Controller = TextEditingController(text: _originalField1);
    _field2Controller = TextEditingController(text: _originalField2);
    _aiPromptController = TextEditingController();
    _field2FocusNode = FocusNode();
    _field2ScrollController = ScrollController();

    // Listen to text changes to detect modifications
    _field1Controller.addListener(_checkForChanges);
    _field2Controller.addListener(_onField2Change);

    // Listen to AI prompt changes to update send button state
    _aiPromptController.addListener(() {
      setState(() {});
    });

    // Listen to focus changes to save/restore selection
    _field2FocusNode.addListener(_onField2FocusChange);

    // Listen to scroll changes to update overlay
    _field2ScrollController.addListener(_onField2ScrollChange);

    // Load persisted AI prompt visibility
    _loadAiPromptPreference();

    // Load assets if image insertion is supported
    if (widget.config.supportsImageInsertion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AssetProvider>(context, listen: false).loadAssets();
        }
      });
    }

    // If opened from search, select the matched text and scroll to it
    if (widget.searchQuery != null && widget.searchLineNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectAndScrollToMatch();
      });
    }
  }

  void _selectAndScrollToMatch() {
    if (widget.searchQuery == null || widget.searchLineNumber == null) return;

    final field2Text = _field2Controller.text;
    final lines = field2Text.split('\n');
    final lineNumber = widget.searchLineNumber!;

    // Check if line number is valid
    if (lineNumber >= lines.length) return;

    // Calculate character position of the start of the target line
    int charPosition = 0;
    for (int i = 0; i < lineNumber; i++) {
      charPosition += lines[i].length + 1; // +1 for newline
    }

    // Find the query within the target line (case-insensitive)
    final targetLine = lines[lineNumber];
    final queryLower = widget.searchQuery!.toLowerCase();
    final lineLower = targetLine.toLowerCase();
    final matchIndex = lineLower.indexOf(queryLower);

    if (matchIndex != -1) {
      final startPos = charPosition + matchIndex;
      final endPos = startPos + widget.searchQuery!.length;

      // Set selection
      final selection = TextSelection(
        baseOffset: startPos,
        extentOffset: endPos,
      );
      _field2Controller.selection = selection;
      _savedSelection = selection;

      // Scroll to make it visible
      // Estimate scroll position based on line number
      final lineHeight = 24.0; // Approximate line height
      final scrollPosition = lineNumber * lineHeight;
      final scrollController = _field2ScrollController;

      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollPosition.clamp(
            0.0,
            scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      // Focus the field2 field to show selection
      _field2FocusNode.requestFocus();
    }
  }

  Future<void> _loadAiPromptPreference() async {
    final showAi = await _uiPrefs.getShowAiPrompt();
    if (mounted) {
      setState(() {
        _showAiPrompt = showAi;
      });
    }
  }

  void _checkForChanges() {
    final hasChanges =
        _field1Controller.text.trim() != _originalField1.trim() ||
        _field2Controller.text.trim() != _originalField2.trim();

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _onField2Change() {
    // Check for changes
    _checkForChanges();

    // Save selection when unfocused
    if (!_field2FocusNode.hasFocus) {
      setState(() {
        _savedSelection = _field2Controller.selection;
      });
    }
  }

  void _onField2FocusChange() {
    setState(() {
      if (_field2FocusNode.hasFocus) {
        if (_savedSelection != null) {
          _field2Controller.selection = _savedSelection!;
        }
      } else {
        _savedSelection = _field2Controller.selection;
      }
    });
  }

  void _onField2ScrollChange() {
    setState(() {
      _scrollOffset = _field2ScrollController.offset;
    });
  }

  @override
  void dispose() {
    _field1Controller.removeListener(_checkForChanges);
    _field2Controller.removeListener(_onField2Change);
    _field2FocusNode.removeListener(_onField2FocusChange);
    _field2ScrollController.removeListener(_onField2ScrollChange);
    _field1Controller.dispose();
    _field2Controller.dispose();
    _aiPromptController.dispose();
    _field2FocusNode.dispose();
    _field2ScrollController.dispose();
    super.dispose();
  }

  void _toggleAiPrompt() {
    setState(() {
      _showAiPrompt = !_showAiPrompt;
    });
    _uiPrefs.setShowAiPrompt(_showAiPrompt);
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Discard Changes?'),
        content: const DSText.bodyMedium(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          DSButton.text(
            label: 'Keep Editing',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DSButton.primary(
            label: 'Discard',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: DSText.titleLarge(widget.config.deleteConfirmationTitle),
        content: DSText.bodyMedium(widget.config.deleteConfirmationMessage),
        actions: [
          DSButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DSButton.primary(
            label: 'Delete',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop({'delete': true});
    }
  }

  Future<void> _insertImageTag() async {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    // Load assets to ensure we have the current list
    await assetProvider.loadAssets();

    if (!mounted) return;

    final assets = assetProvider.assets;

    if (assets.isEmpty) return;

    // Show dialog to select asset
    final selectedAsset = await showDialog<Asset>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Select Image'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return ListTile(
                leading: asset.hasThumbnail
                    ? Image.memory(
                        asset.thumbnail!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.image,
                        size: 40,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                title: DSText.bodyMedium(asset.alias),
                subtitle: DSText.bodySmall(asset.filename),
                onTap: () => Navigator.of(dialogContext).pop(asset),
              );
            },
          ),
        ),
        actions: [
          DSButton.text(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );

    if (selectedAsset != null && mounted) {
      // Insert markdown image tag at cursor/selection
      final selection = _field2Controller.selection;
      final field2Text = _field2Controller.text;
      final imageTag = '![](${selectedAsset.alias})';

      setState(() {
        final newText = field2Text.replaceRange(
          selection.start,
          selection.end,
          imageTag,
        );
        _field2Controller.text = newText;

        // Place cursor after the inserted tag
        final newCursorPos = selection.start + imageTag.length;
        final newSelection = TextSelection.collapsed(offset: newCursorPos);
        _field2Controller.selection = newSelection;
        _savedSelection = newSelection;
      });

      // Focus the field2 field
      _field2FocusNode.requestFocus();
    }
  }

  Future<void> _sendAiPrompt() async {
    if (_aiPromptController.text.isEmpty) return;

    setState(() {
      _isLoadingAi = true;
    });

    try {
      // Capture provider before async operations
      final usageProvider = Provider.of<AIUsageProvider>(
        context,
        listen: false,
      );

      // If command mode is enabled, save current edits first
      if (_enableCommands && widget.config.supportsCommandMode) {
        if (!_formKey.currentState!.validate()) return;

        final updatedEntity = widget.copyWith(
          widget.entity,
          _field1Controller.text,
          _field2Controller.text,
        );

        await widget.onUpdate(context, updatedEntity);

        // Update original values to mark as saved
        if (mounted) {
          setState(() {
            _originalField1 = _field1Controller.text;
            _originalField2 = _field2Controller.text;
            _hasChanges = false;
          });
        }
      }

      final bookDataService = BookDataService();
      final bookData = await bookDataService.collectAllBookData();

      // Get cursor position, or use end of field2 if no valid selection
      var selection = _field2Controller.selection;
      final field2Text = _field2Controller.text;

      // If selection is invalid, use end of field2
      if (!selection.isValid) {
        selection = TextSelection.collapsed(offset: field2Text.length);
      }

      final contextData = {
        'currentItem': {
          'type': widget.config.entityType,
          'id': widget.getId(widget.entity),
          widget.config.field1Key: _field1Controller.text,
          widget.config.field2Key: field2Text,
          'cursorPosition': selection.start,
          'selectedText': selection.isValid && !selection.isCollapsed
              ? field2Text.substring(selection.start, selection.end)
              : '',
          'textBeforeCursor': selection.isValid
              ? field2Text.substring(0, selection.start)
              : '',
          'textAfterCursor': selection.isValid
              ? field2Text.substring(selection.end)
              : '',
        },
        'bookData': bookData,
        'enableCommands': _enableCommands && widget.config.supportsCommandMode,
      };

      final aiService = AIService();
      final response = await aiService.sendPrompt(
        prompt: _aiPromptController.text,
        context: contextData,
        usageProvider: usageProvider,
        contextType: widget.config.entityType,
        contextId: widget.getId(widget.entity),
        contextName: _field1Controller.text,
      );

      if (response != null && mounted) {
        // Handle commands if present
        if (response.hasCommands) {
          final executor = AICommandExecutor();
          final results = await executor.executeCommands(
            context,
            response.commands,
          );

          // Show results
          final successCount = results.where((r) => r.success).length;
          final failCount = results.where((r) => !r.success).length;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Commands executed: $successCount succeeded, $failCount failed',
                ),
                backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
              ),
            );
          }
        }
        // Handle text response - insert at cursor or replace selection
        else if (response.hasText) {
          setState(() {
            final newText = field2Text.replaceRange(
              selection.start,
              selection.end,
              response.text!,
            );
            _field2Controller.text = newText;
            // Select the inserted text
            final newSelection = TextSelection(
              baseOffset: selection.start,
              extentOffset: selection.start + response.text!.length,
            );
            _field2Controller.selection = newSelection;
            _savedSelection = newSelection;
          });
          // Restore focus to field2 to show selection
          _field2FocusNode.requestFocus();
        }
      } else if (mounted) {
        // Show error if no API key or request failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI request failed. Please check your API key in settings.',
            ),
          ),
        );
      }

      _aiPromptController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
        });
      }
    }
  }

  String _getTemplateSubstitutedPrompt(String promptContent) {
    // Basic substitutions for {title}/{name}
    var result = promptContent
        .replaceAll('{title}', _field1Controller.text)
        .replaceAll('{name}', _field1Controller.text);

    // Chapter-specific {chapter} substitution
    if (widget.config.entityType == 'chapter' && widget.getOrderIndex != null) {
      final chapterProvider = Provider.of<ChapterProvider>(
        context,
        listen: false,
      );
      final hasPrologue =
          chapterProvider.chapters.isNotEmpty &&
          chapterProvider.chapters.first.orderIndex == 0 &&
          chapterProvider.chapters.first.title.toLowerCase() == 'prologue';

      final orderIndex = widget.getOrderIndex!(widget.entity) ?? 0;
      final isPrologue =
          orderIndex == 0 && _field1Controller.text.toLowerCase() == 'prologue';

      final String chapterText;
      if (isPrologue) {
        chapterText = 'Prologue';
      } else if (hasPrologue) {
        chapterText = 'Chapter $orderIndex: ${_field1Controller.text}';
      } else {
        chapterText = 'Chapter ${orderIndex + 1}: ${_field1Controller.text}';
      }

      result = result.replaceAll('{chapter}', chapterText);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges && !_isLoadingAi,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Prevent dismissal if AI is loading
        if (_isLoadingAi) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait for AI to finish'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AlertDialog(
        title: DSText.titleLarge(widget.config.dialogTitle),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _field1Controller,
                  decoration: InputDecoration(
                    labelText: widget.config.field1Label,
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !_isLoadingAi,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.config.field1ValidationMessage;
                    }
                    return null;
                  },
                ),
                const DSSpacing.spacing16(),
                Stack(
                  children: [
                    TextFormField(
                      controller: _field2Controller,
                      focusNode: _field2FocusNode,
                      scrollController: _field2ScrollController,
                      decoration: InputDecoration(
                        labelText: widget.config.field2Label,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.fromLTRB(
                          12,
                          20,
                          12,
                          20,
                        ),
                      ),
                      maxLines: widget.config.field2MaxLines,
                      readOnly: _isLoadingAi,
                      showCursor: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return widget.config.field2ValidationMessage;
                        }
                        return null;
                      },
                    ),
                    if (!_field2FocusNode.hasFocus && _savedSelection != null)
                      Positioned.fill(
                        child: ClipRect(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                19,
                                12,
                                20,
                              ),
                              child: TextSelectionHighlight(
                                text: _field2Controller.text,
                                selection: _savedSelection!,
                                style:
                                    Theme.of(context).textTheme.bodyLarge ??
                                    const TextStyle(fontSize: 16.0),
                                maxLines: widget.config.field2MaxLines,
                                scrollOffset: _scrollOffset,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_showAiPrompt) ...[
                  const DSSpacing.spacing16(),
                  if (widget.config.supportsCommandMode)
                    CheckboxListTile(
                      title: const DSText.bodySmall('Enable command mode'),
                      subtitle: const DSText.bodySmall(
                        'Allow AI to create new chapters, characters, plots, and notes',
                      ),
                      value: _enableCommands,
                      onChanged: _isLoadingAi
                          ? null
                          : (value) {
                              setState(() {
                                _enableCommands = value ?? false;
                              });
                            },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (widget.config.supportsCommandMode)
                    const DSSpacing.spacing8(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _aiPromptController,
                          decoration: InputDecoration(
                            labelText: 'AI Prompt',
                            border: const OutlineInputBorder(),
                            hintText:
                                _enableCommands &&
                                    widget.config.supportsCommandMode
                                ? widget.config.aiPromptHintCommandMode
                                : widget.config.aiPromptHint,
                          ),
                          maxLines: 2,
                          enabled: !_isLoadingAi,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing8),
                      if (_isLoadingAi)
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Column(
                          children: [
                            PopupMenuButton<Prompt>(
                              icon: const Icon(Icons.bookmark),
                              tooltip: 'Use Template',
                              onSelected: (template) {
                                setState(() {
                                  final promptText =
                                      _getTemplateSubstitutedPrompt(
                                        template.content,
                                      );
                                  _aiPromptController.text = promptText;
                                  if (widget.config.supportsCommandMode) {
                                    _enableCommands = template.command;
                                  }
                                });
                              },
                              itemBuilder: (context) {
                                final promptProvider =
                                    Provider.of<PromptProvider>(
                                      context,
                                      listen: false,
                                    );
                                final templates = promptProvider.prompts
                                    .where(
                                      (p) =>
                                          p.isTemplate &&
                                          (!p.command ||
                                              widget
                                                  .config
                                                  .supportsCommandMode),
                                    )
                                    .toList();

                                if (templates.isEmpty) {
                                  return [
                                    const PopupMenuItem(
                                      enabled: false,
                                      child: DSText.bodySmall(
                                        'No templates available',
                                      ),
                                    ),
                                  ];
                                }

                                return templates.map((template) {
                                  return PopupMenuItem<Prompt>(
                                    value: template,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DSText.bodyMedium(template.title),
                                        if (template.command)
                                          DSText.bodySmall(
                                            'Command mode',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed:
                                  _aiPromptController.text.isEmpty ||
                                      (!_enableCommands &&
                                          (_savedSelection == null ||
                                              !_savedSelection!.isValid))
                                  ? null
                                  : _sendAiPrompt,
                              tooltip: 'Send',
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              DSButton.text(
                label: 'Delete',
                onPressed: _isLoadingAi ? null : _confirmDelete,
              ),
              IconButton(
                icon: Opacity(
                  opacity: _showAiPrompt ? 1.0 : 0.6,
                  child: SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/OpenAI-white-monoblossom.svg'
                        : 'assets/images/OpenAI-black-monoblossom.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
                onPressed: widget.hasApiKey && !_isLoadingAi
                    ? _toggleAiPrompt
                    : null,
                tooltip: widget.hasApiKey
                    ? 'AI Assistant'
                    : 'AI Assistant (API key required)',
              ),
              if (widget.config.supportsImageInsertion)
                Consumer<AssetProvider>(
                  builder: (context, assetProvider, child) {
                    final hasAssets = assetProvider.assets.isNotEmpty;
                    return IconButton(
                      icon: const Icon(Icons.add_photo_alternate),
                      onPressed: hasAssets && !_isLoadingAi
                          ? _insertImageTag
                          : null,
                      tooltip: hasAssets
                          ? 'Insert Image'
                          : 'Insert Image (no assets available)',
                    );
                  },
                ),
              const Spacer(),
              DSButton.text(
                label: 'Close',
                onPressed: _isLoadingAi
                    ? null
                    : () async {
                        final shouldClose = await _confirmDiscard();
                        if (shouldClose && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
              DSButton.primary(
                label: 'Save',
                onPressed: !_hasChanges || _isLoadingAi
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          // Capture messenger before async operations
                          final messenger = ScaffoldMessenger.of(context);

                          // Save changes
                          final updatedEntity = widget.copyWith(
                            widget.entity,
                            _field1Controller.text,
                            _field2Controller.text,
                          );
                          await widget.onUpdate(context, updatedEntity);

                          // Update original values to mark as saved
                          setState(() {
                            _originalField1 = _field1Controller.text;
                            _originalField2 = _field2Controller.text;
                            _hasChanges = false;
                          });

                          // Show feedback
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(widget.config.savedMessage),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
