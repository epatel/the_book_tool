import 'package:the_book_tool/index.dart';

class SettingsDialog extends StatefulWidget {
  final String name;
  final String author;
  final bool markdown;
  final String apiKey;

  const SettingsDialog({
    super.key,
    required this.name,
    required this.author,
    required this.markdown,
    required this.apiKey,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _apiKeyController;
  late bool _markdownEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _authorController = TextEditingController(text: widget.author);
    _apiKeyController = TextEditingController(text: widget.apiKey);
    _markdownEnabled = widget.markdown;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Settings'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Book Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const DSSpacing.spacing16(),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
              ),
              const DSSpacing.spacing16(),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  border: OutlineInputBorder(),
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const DSSpacing.spacing16(),
              Row(
                children: [
                  Checkbox(
                    value: _markdownEnabled,
                    onChanged: (value) {
                      setState(() {
                        _markdownEnabled = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  const DSText.bodyMedium('Enable Markdown rendering'),
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
          label: 'Save',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'author': _authorController.text,
                'markdown': _markdownEnabled,
                'apiKey': _apiKeyController.text,
              });
            }
          },
        ),
      ],
    );
  }
}
