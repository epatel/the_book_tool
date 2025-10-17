import 'package:the_book_tool/index.dart';

class AddPromptDialog extends StatefulWidget {
  const AddPromptDialog({super.key});

  @override
  State<AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<AddPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _command = false;
  bool _isTemplate = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Add Prompt'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 500,
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
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a prompt';
                  }
                  return null;
                },
              ),
              const DSSpacing.spacing16(),
              Row(
                children: [
                  Tooltip(
                    message: 'Enable command mode to create new chapters, characters, plots, or notes',
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
                    message: 'Mark as template to save for later use (disables send)',
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
        ),
      ),
      actions: [
        DSButton.text(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DSButton.primary(
          label: 'Add',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'content': _contentController.text,
                'command': _command,
                'isTemplate': _isTemplate,
              });
            }
          },
        ),
      ],
    );
  }
}
