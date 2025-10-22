import 'package:the_book_tool/index.dart';

class EditPromptDialog extends StatefulWidget {
  final Prompt? prompt;
  final bool hasApiKey;

  const EditPromptDialog({
    super.key,
    this.prompt,
    required this.hasApiKey,
  });

  @override
  State<EditPromptDialog> createState() => _EditPromptDialogState();
}

class _EditPromptDialogState extends State<EditPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _command;
  late bool _isTemplate;
  late final String _originalContent;
  String? _response;
  bool _hasChanges = false;
  String _originalTitle = '';
  bool _originalCommand = false;
  bool _originalIsTemplate = false;

  // Computed properties for button states
  bool get _hasBothFields =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  bool get _canSend => _hasBothFields && !_isTemplate && widget.hasApiKey;

  bool get _canSaveOrAdd => _hasChanges && _hasBothFields;

  @override
  void initState() {
    super.initState();
    final prompt = widget.prompt;

    if (prompt != null) {
      // Editing existing prompt
      _originalTitle = prompt.title;
      _originalContent = prompt.content;
      _originalCommand = prompt.command;
      _originalIsTemplate = prompt.isTemplate;

      _titleController = TextEditingController(text: prompt.title);
      _contentController = TextEditingController(text: prompt.content);
      _command = prompt.command;
      _isTemplate = prompt.isTemplate;
      _response = prompt.response;
    } else {
      // Adding new prompt
      _originalTitle = '';
      _originalContent = '';
      _originalCommand = false;
      _originalIsTemplate = false;

      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _command = false;
      _isTemplate = false;
      _response = null;
      // _hasChanges starts as false; button enables when user types
    }

    // Listen to text changes to detect modifications
    _titleController.addListener(_checkForChanges);
    _contentController.addListener(_onContentChange);
  }

  void _checkForChanges() {
    final hasChanges =
        _titleController.text.trim() != _originalTitle.trim() ||
        _contentController.text.trim() != _originalContent.trim() ||
        _command != _originalCommand ||
        _isTemplate != _originalIsTemplate;

    // Always call setState to re-evaluate computed getters
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  void _onContentChange() {
    // Check for changes
    _checkForChanges();

    // Clear response if content has changed from original
    if (_contentController.text != _originalContent) {
      _response = null;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkForChanges);
    _contentController.removeListener(_onContentChange);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
        title: const DSText.titleLarge('Delete Prompt'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete this prompt? This action cannot be undone.',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AlertDialog(
        title: DSText.titleLarge(
          widget.prompt == null ? 'Add Prompt' : 'Edit Prompt',
        ),
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
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a prompt';
                    }
                    return null;
                  },
                ),
                const DSSpacing.spacing8(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Tooltip(
                              message:
                                  'Enable command mode to create new chapters, characters, plots, or notes',
                              child: Checkbox(
                                value: _command,
                                onChanged: (value) {
                                  setState(() {
                                    _command = value ?? false;
                                  });
                                  _checkForChanges();
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            const DSText.bodyMedium('Command'),
                          ],
                        ),
                        Row(
                          children: [
                            Tooltip(
                              message:
                                  'Mark as template to save for later use (disables send)',
                              child: Checkbox(
                                value: _isTemplate,
                                onChanged: (value) {
                                  setState(() {
                                    _isTemplate = value ?? false;
                                  });
                                  _checkForChanges();
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            const DSText.bodyMedium('Template'),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_response != null &&
                            _response!.isNotEmpty &&
                            !_command &&
                            !_isTemplate)
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AIResponseDialog(
                                  response: _response!,
                                ),
                              );
                            },
                            tooltip: 'View Response',
                          ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _canSend
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.of(context).pop({
                                      'title': _titleController.text,
                                      'content': _contentController.text,
                                      'response': _response,
                                      'command': _command,
                                      'isTemplate': _isTemplate,
                                      'send': true,
                                    });
                                  }
                                }
                              : null,
                          tooltip: 'Send',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              if (widget.prompt != null)
                DSButton.text(label: 'Delete', onPressed: _confirmDelete),
              const Spacer(),
              DSButton.text(
                label: widget.prompt == null ? 'Cancel' : 'Close',
                onPressed: () async {
                  final shouldClose = await _confirmDiscard();
                  if (shouldClose && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              DSButton.primary(
                label: widget.prompt == null ? 'Add' : 'Save',
                onPressed: _canSaveOrAdd
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            'title': _titleController.text,
                            'content': _contentController.text,
                            'response': _response,
                            'command': _command,
                            'isTemplate': _isTemplate,
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
