import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddEntityDialog extends StatefulWidget {
  final AddEntityDialogConfig config;
  final bool hasApiKey;

  const AddEntityDialog({
    super.key,
    required this.config,
    this.hasApiKey = false,
  });

  @override
  State<AddEntityDialog> createState() => _AddEntityDialogState();
}

class _AddEntityDialogState extends State<AddEntityDialog> {
  final _formKey = GlobalKey<FormState>();
  final UiPreferencesService _uiPrefs = UiPreferencesService();
  final _field1Controller = TextEditingController();
  final _field2Controller = TextEditingController();
  late final TextEditingController _aiPromptController;
  late final FocusNode _field2FocusNode;
  late final ScrollController _field2ScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _aiPromptController = TextEditingController();
    _field2FocusNode = FocusNode();
    _field2ScrollController = ScrollController();

    // Listen to AI prompt changes to update send button state
    _aiPromptController.addListener(() {
      setState(() {});
    });

    // Listen to field2 changes to save selection
    _field2Controller.addListener(_onField2Change);

    // Listen to focus changes to save/restore selection
    _field2FocusNode.addListener(_onField2FocusChange);

    // Listen to scroll changes to update overlay
    _field2ScrollController.addListener(_onField2ScrollChange);

    // Load persisted AI prompt visibility
    _loadAiPromptPreference();
  }

  void _onField2Change() {
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

  Future<void> _loadAiPromptPreference() async {
    final showAi = await _uiPrefs.getShowAiPrompt();
    if (mounted) {
      setState(() {
        _showAiPrompt = showAi;
      });
    }
  }

  void _toggleAiPrompt() {
    setState(() {
      _showAiPrompt = !_showAiPrompt;
    });
    _uiPrefs.setShowAiPrompt(_showAiPrompt);
  }

  bool _hasContent() {
    return _field1Controller.text.trim().isNotEmpty ||
        _field2Controller.text.trim().isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasContent()) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Discard Changes?'),
        content: const DSText.bodyMedium(
          'You have unsaved content. Are you sure you want to discard it?',
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
        'enableCommands': false,
      };

      final aiService = AIService();
      final response = await aiService.sendPrompt(
        prompt: _aiPromptController.text,
        context: contextData,
        usageProvider: usageProvider,
      );

      if (response != null && mounted) {
        // Handle text response - insert at cursor or replace selection
        if (response.hasText) {
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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasContent() && !_isLoadingAi,
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
                        contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _aiPromptController,
                          decoration: InputDecoration(
                            labelText: 'AI Prompt',
                            border: const OutlineInputBorder(),
                            hintText: widget.config.aiPromptHint,
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
                                  // Substitute {title}/{name} with field1's value
                                  final promptText = template.content
                                      .replaceAll(
                                        '{title}',
                                        _field1Controller.text,
                                      )
                                      .replaceAll(
                                        '{name}',
                                        _field1Controller.text,
                                      );
                                  _aiPromptController.text = promptText;
                                });
                              },
                              itemBuilder: (context) {
                                final promptProvider =
                                    Provider.of<PromptProvider>(
                                      context,
                                      listen: false,
                                    );
                                final templates = promptProvider.prompts
                                    .where((p) => p.isTemplate && !p.command)
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
                              onPressed: _aiPromptController.text.isEmpty
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
                onPressed: widget.hasApiKey && !_isLoadingAi ? _toggleAiPrompt : null,
                tooltip: widget.hasApiKey
                    ? 'AI Assistant'
                    : 'AI Assistant (API key required)',
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
                label: 'Add',
                onPressed: _isLoadingAi
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            widget.config.field1Key: _field1Controller.text,
                            widget.config.field2Key: _field2Controller.text,
                          });
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
