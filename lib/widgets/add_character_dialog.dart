import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddCharacterDialog extends StatefulWidget {
  final bool hasApiKey;

  const AddCharacterDialog({
    super.key,
    this.hasApiKey = false,
  });

  @override
  State<AddCharacterDialog> createState() => _AddCharacterDialogState();
}

class _AddCharacterDialogState extends State<AddCharacterDialog> {
  final _formKey = GlobalKey<FormState>();
  final UiPreferencesService _uiPrefs = UiPreferencesService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _aiPromptController;
  late final FocusNode _descriptionFocusNode;
  late final ScrollController _descriptionScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _aiPromptController = TextEditingController();
    _descriptionFocusNode = FocusNode();
    _descriptionScrollController = ScrollController();

    // Listen to AI prompt changes to update send button state
    _aiPromptController.addListener(() {
      setState(() {});
    });

    // Listen to description changes to save selection
    _descriptionController.addListener(_onDescriptionChange);

    // Listen to focus changes to save/restore selection
    _descriptionFocusNode.addListener(_onDescriptionFocusChange);

    // Listen to scroll changes to update overlay
    _descriptionScrollController.addListener(_onDescriptionScrollChange);

    // Load persisted AI prompt visibility
    _loadAiPromptPreference();
  }

  void _onDescriptionChange() {
    // Save selection when unfocused
    if (!_descriptionFocusNode.hasFocus) {
      setState(() {
        _savedSelection = _descriptionController.selection;
      });
    }
  }

  void _onDescriptionFocusChange() {
    setState(() {
      if (_descriptionFocusNode.hasFocus) {
        if (_savedSelection != null) {
          _descriptionController.selection = _savedSelection!;
        }
      } else {
        _savedSelection = _descriptionController.selection;
      }
    });
  }

  void _onDescriptionScrollChange() {
    setState(() {
      _scrollOffset = _descriptionScrollController.offset;
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
    return _nameController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;
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

      // Get cursor position, or use end of description if no valid selection
      var selection = _descriptionController.selection;
      final description = _descriptionController.text;

      // If selection is invalid, use end of description
      if (!selection.isValid) {
        selection = TextSelection.collapsed(offset: description.length);
      }

      final contextData = {
        'currentItem': {
          'type': 'character',
          'name': _nameController.text,
          'description': description,
          'cursorPosition': selection.start,
          'selectedText': selection.isValid && !selection.isCollapsed
              ? description.substring(selection.start, selection.end)
              : '',
          'textBeforeCursor': selection.isValid
              ? description.substring(0, selection.start)
              : '',
          'textAfterCursor': selection.isValid
              ? description.substring(selection.end)
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
            final newText = description.replaceRange(
              selection.start,
              selection.end,
              response.text!,
            );
            _descriptionController.text = newText;
            // Select the inserted text
            final newSelection = TextSelection(
              baseOffset: selection.start,
              extentOffset: selection.start + response.text!.length,
            );
            _descriptionController.selection = newSelection;
            _savedSelection = newSelection;
          });
          // Restore focus to description field to show selection
          _descriptionFocusNode.requestFocus();
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
    _descriptionController.removeListener(_onDescriptionChange);
    _descriptionFocusNode.removeListener(_onDescriptionFocusChange);
    _descriptionScrollController.removeListener(_onDescriptionScrollChange);
    _nameController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
    _descriptionFocusNode.dispose();
    _descriptionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasContent(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AlertDialog(
        title: const DSText.titleLarge('Add Character'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const DSSpacing.spacing16(),
                Stack(
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      scrollController: _descriptionScrollController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                      ),
                      maxLines: 5,
                      readOnly: _isLoadingAi,
                      showCursor: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    if (!_descriptionFocusNode.hasFocus &&
                        _savedSelection != null)
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
                                text: _descriptionController.text,
                                selection: _savedSelection!,
                                style:
                                    Theme.of(context).textTheme.bodyLarge ??
                                    const TextStyle(fontSize: 16.0),
                                maxLines: 5,
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
                          decoration: const InputDecoration(
                            labelText: 'AI Prompt',
                            border: OutlineInputBorder(),
                            hintText:
                                'AI will insert at cursor or at end of description...',
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
                                  // Substitute {title}/{name} with the character's name
                                  final promptText = template.content
                                      .replaceAll(
                                        '{title}',
                                        _nameController.text,
                                      )
                                      .replaceAll(
                                        '{name}',
                                        _nameController.text,
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
                onPressed: widget.hasApiKey ? _toggleAiPrompt : null,
                tooltip: widget.hasApiKey
                    ? 'AI Assistant'
                    : 'AI Assistant (API key required)',
              ),
              const Spacer(),
              DSButton.text(
                label: 'Close',
                onPressed: () async {
                  final shouldClose = await _confirmDiscard();
                  if (shouldClose && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              DSButton.primary(
                label: 'Add',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop({
                      'name': _nameController.text,
                      'description': _descriptionController.text,
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
