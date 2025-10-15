import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditChapterDialog extends StatefulWidget {
  final Chapter chapter;
  final bool hasApiKey;

  const EditChapterDialog({
    super.key,
    required this.chapter,
    this.hasApiKey = false,
  });

  @override
  State<EditChapterDialog> createState() => _EditChapterDialogState();
}

class _EditChapterDialogState extends State<EditChapterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _aiPromptController;
  late final FocusNode _contentFocusNode;
  late final ScrollController _contentScrollController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter.title);
    _contentController = TextEditingController(text: widget.chapter.content);
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
        title: const DSText.titleLarge('Delete Chapter'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete this chapter? This action cannot be undone.',
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
          'type': 'chapter',
          'id': widget.chapter.id,
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
        'enableCommands': false,
      };

      final aiService = AIService();
      final response = await aiService.sendPrompt(
        prompt: _aiPromptController.text,
        context: context,
      );

      if (response != null && mounted) {
        // Handle text response - insert at cursor or replace selection
        if (response.hasText) {
          setState(() {
            final newText = content.replaceRange(
              selection.start,
              selection.end,
              response.text!,
            );
            _contentController.text = newText;
            // Move cursor to end of inserted text
            _contentController.selection = TextSelection.collapsed(
              offset: selection.start + response.text!.length,
            );
          });
          // Restore focus to content field to show cursor
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
      title: const DSText.titleLarge('Edit Chapter'),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aiPromptController,
                        decoration: const InputDecoration(
                          labelText: 'AI Prompt',
                          border: OutlineInputBorder(),
                          hintText:
                              'AI will insert at cursor or replace selection...',
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
