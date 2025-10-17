import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditPlotDialog extends StatefulWidget {
  final Plot plot;
  final bool hasApiKey;

  const EditPlotDialog({
    super.key,
    required this.plot,
    this.hasApiKey = false,
  });

  @override
  State<EditPlotDialog> createState() => _EditPlotDialogState();
}

class _EditPlotDialogState extends State<EditPlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _aiPromptController;
  late final FocusNode _descriptionFocusNode;
  late final ScrollController _descriptionScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  bool _enableCommands = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plot.title);
    _descriptionController = TextEditingController(
      text: widget.plot.description,
    );
    _aiPromptController = TextEditingController();
    _descriptionFocusNode = FocusNode();
    _descriptionScrollController = ScrollController();

    // Listen to AI prompt changes to update send button state
    _aiPromptController.addListener(() {
      setState(() {});
    });

    // Listen to focus changes to save/restore selection
    _descriptionFocusNode.addListener(_onDescriptionFocusChange);

    // Listen to scroll changes to update overlay
    _descriptionScrollController.addListener(_onDescriptionScrollChange);

    // Listen to selection changes to update saved selection when unfocused
    _descriptionController.addListener(_onDescriptionSelectionChange);
  }

  void _onDescriptionSelectionChange() {
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

  @override
  void dispose() {
    _descriptionFocusNode.removeListener(_onDescriptionFocusChange);
    _descriptionScrollController.removeListener(_onDescriptionScrollChange);
    _descriptionController.removeListener(_onDescriptionSelectionChange);
    _titleController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
    _descriptionFocusNode.dispose();
    _descriptionScrollController.dispose();
    super.dispose();
  }

  void _toggleAiPrompt() {
    setState(() {
      _showAiPrompt = !_showAiPrompt;
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Delete Plot'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete this plot? This action cannot be undone.',
        ),
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

  Future<void> _sendAiPrompt() async {
    if (_aiPromptController.text.isEmpty) return;

    // If command mode is enabled, save current edits first
    if (_enableCommands) {
      if (!_formKey.currentState!.validate()) return;

      final updatedPlot = widget.plot.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
      );

      await Provider.of<PlotProvider>(
        context,
        listen: false,
      ).updatePlot(updatedPlot);
    }

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final bookDataService = BookDataService();
      final bookData = await bookDataService.collectAllBookData();

      // Capture cursor position and selection for non-command mode
      final selection = _descriptionController.selection;
      final description = _descriptionController.text;

      final context = {
        'currentItem': {
          'type': 'plot',
          'id': widget.plot.id,
          'title': _titleController.text,
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
        'enableCommands': _enableCommands,
      };

      final aiService = AIService();
      final response = await aiService.sendPrompt(
        prompt: _aiPromptController.text,
        context: context,
      );

      if (response != null && mounted) {
        // Handle commands if present
        if (response.hasCommands) {
          final executor = AICommandExecutor();
          final results = await executor.executeCommands(
            this.context,
            response.commands,
          );

          // Show results
          final successCount = results.where((r) => r.success).length;
          final failCount = results.where((r) => !r.success).length;

          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
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
        ScaffoldMessenger.of(this.context).showSnackBar(
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Edit Plot Idea'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                    maxLines: 10,
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
                            padding: const EdgeInsets.fromLTRB(16, 19, 12, 20),
                            child: TextSelectionHighlight(
                              text: _descriptionController.text,
                              selection: _savedSelection!,
                              style:
                                  Theme.of(context).textTheme.bodyLarge ??
                                  const TextStyle(fontSize: 16.0),
                              maxLines: 10,
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
                const DSSpacing.spacing8(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aiPromptController,
                        decoration: InputDecoration(
                          labelText: 'AI Prompt',
                          border: const OutlineInputBorder(),
                          hintText: _enableCommands
                              ? 'AI can create new items with commands...'
                              : 'AI will insert at cursor or replace selection...',
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
                                // Substitute {title}/{name} with the item's actual title
                                final promptText = template.content
                                    .replaceAll('{title}', _titleController.text)
                                    .replaceAll('{name}', _titleController.text);
                                _aiPromptController.text = promptText;
                                _enableCommands = template.command;
                              });
                            },
                            itemBuilder: (context) {
                              final promptProvider = Provider.of<PromptProvider>(
                                context,
                                listen: false,
                              );
                              final templates = promptProvider.prompts
                                  .where((p) => p.isTemplate)
                                  .toList();

                              if (templates.isEmpty) {
                                return [
                                  const PopupMenuItem(
                                    enabled: false,
                                    child: DSText.bodySmall('No templates available'),
                                  ),
                                ];
                              }

                              return templates.map((template) {
                                return PopupMenuItem<Prompt>(
                                  value: template,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DSText.bodyMedium(template.title),
                                      if (template.command)
                                        DSText.bodySmall(
                                          'Command mode',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
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
            DSButton.text(label: 'Delete', onPressed: _confirmDelete),
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
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            DSButton.primary(
              label: 'Save',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
