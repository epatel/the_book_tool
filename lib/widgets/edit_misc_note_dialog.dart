import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditMiscNoteDialog extends StatefulWidget {
  final MiscNote note;
  final bool hasApiKey;

  const EditMiscNoteDialog({
    super.key,
    required this.note,
    this.hasApiKey = false,
  });

  @override
  State<EditMiscNoteDialog> createState() => _EditMiscNoteDialogState();
}

class _EditMiscNoteDialogState extends State<EditMiscNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _aiPromptController;
  late final FocusNode _contentFocusNode;
  late final ScrollController _contentScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  bool _enableCommands = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _aiPromptController = TextEditingController();
    _contentFocusNode = FocusNode();
    _contentScrollController = ScrollController();

    // Listen to AI prompt changes to update send button state
    _aiPromptController.addListener(() {
      setState(() {});
    });

    // Listen to focus changes to save/restore selection
    _contentFocusNode.addListener(_onContentFocusChange);

    // Listen to scroll changes to update overlay
    _contentScrollController.addListener(_onContentScrollChange);

    // Listen to selection changes to update saved selection when unfocused
    _contentController.addListener(_onContentSelectionChange);
  }

  void _onContentSelectionChange() {
    if (!_contentFocusNode.hasFocus) {
      setState(() {
        _savedSelection = _contentController.selection;
      });
    }
  }

  void _onContentFocusChange() {
    setState(() {
      if (_contentFocusNode.hasFocus) {
        if (_savedSelection != null) {
          _contentController.selection = _savedSelection!;
        }
      } else {
        _savedSelection = _contentController.selection;
      }
    });
  }

  void _onContentScrollChange() {
    setState(() {
      _scrollOffset = _contentScrollController.offset;
    });
  }

  @override
  void dispose() {
    _contentFocusNode.removeListener(_onContentFocusChange);
    _contentScrollController.removeListener(_onContentScrollChange);
    _contentController.removeListener(_onContentSelectionChange);
    _titleController.dispose();
    _contentController.dispose();
    _aiPromptController.dispose();
    _contentFocusNode.dispose();
    _contentScrollController.dispose();
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
        title: const DSText.titleLarge('Delete Note'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete this note? This action cannot be undone.',
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

      final updatedNote = widget.note.copyWith(
        title: _titleController.text,
        content: _contentController.text,
      );

      await Provider.of<MiscNoteProvider>(
        context,
        listen: false,
      ).updateNote(updatedNote);
    }

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final bookDataService = BookDataService();
      final bookData = await bookDataService.collectAllBookData();

      // Capture cursor position and selection for non-command mode
      final selection = _contentController.selection;
      final content = _contentController.text;

      final context = {
        'currentItem': {
          'type': 'miscNote',
          'id': widget.note.id,
          'title': _titleController.text,
          'content': content,
          'cursorPosition': selection.start,
          'selectedText': selection.isValid && !selection.isCollapsed
              ? content.substring(selection.start, selection.end)
              : '',
          'textBeforeCursor': selection.isValid
              ? content.substring(0, selection.start)
              : '',
          'textAfterCursor': selection.isValid
              ? content.substring(selection.end)
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
            final newText = content.replaceRange(
              selection.start,
              selection.end,
              response.text!,
            );
            _contentController.text = newText;
            // Select the inserted text
            final newSelection = TextSelection(
              baseOffset: selection.start,
              extentOffset: selection.start + response.text!.length,
            );
            _contentController.selection = newSelection;
            _savedSelection = newSelection;
          });
          // Restore focus to content field to show selection
          _contentFocusNode.requestFocus();
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
      title: const DSText.titleLarge('Edit Note'),
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
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    scrollController: _contentScrollController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                    ),
                    maxLines: 10,
                    readOnly: _isLoadingAi,
                    showCursor: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter content';
                      }
                      return null;
                    },
                  ),
                  if (!_contentFocusNode.hasFocus && _savedSelection != null)
                    Positioned.fill(
                      child: ClipRect(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 19, 12, 20),
                            child: TextSelectionHighlight(
                              text: _contentController.text,
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
                    'content': _contentController.text,
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
