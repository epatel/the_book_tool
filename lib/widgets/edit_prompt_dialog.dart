import 'package:the_book_tool/index.dart';

class EditPromptDialog extends StatefulWidget {
  final Prompt prompt;

  const EditPromptDialog({
    super.key,
    required this.prompt,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prompt.title);
    _contentController = TextEditingController(text: widget.prompt.content);
    _command = widget.prompt.command;
    _isTemplate = widget.prompt.isTemplate;
    _originalContent = widget.prompt.content;
    _response = widget.prompt.response;

    // Listen to content changes to update send button state and clear response if changed
    _contentController.addListener(() {
      setState(() {
        // Clear response if content has changed from original
        if (_contentController.text != _originalContent) {
          _response = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
    return AlertDialog(
      title: const DSText.titleLarge('Edit Prompt'),
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
                        onPressed:
                            _contentController.text.isEmpty || _isTemplate
                            ? null
                            : () {
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
                              },
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
            DSButton.text(label: 'Delete', onPressed: _confirmDelete),
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
                    'response': _response,
                    'command': _command,
                    'isTemplate': _isTemplate,
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
