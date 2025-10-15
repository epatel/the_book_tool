import 'package:the_book_tool/index.dart';

class SettingsDialog extends StatefulWidget {
  final String name;
  final String author;
  final bool markdown;
  final String apiKey;
  final String contextPrompt;
  final ThemeMode themeMode;
  final ReadingFont readingFont;
  final double fontSize;

  const SettingsDialog({
    super.key,
    required this.name,
    required this.author,
    required this.markdown,
    required this.apiKey,
    this.contextPrompt = '',
    required this.themeMode,
    required this.readingFont,
    this.fontSize = 14.0,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _contextPromptController;
  late bool _markdownEnabled;
  late ThemeMode _themeMode;
  late ReadingFont _readingFont;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _authorController = TextEditingController(text: widget.author);
    _apiKeyController = TextEditingController(text: widget.apiKey);
    _contextPromptController = TextEditingController(
      text: widget.contextPrompt,
    );
    _markdownEnabled = widget.markdown;
    _themeMode = widget.themeMode;
    _readingFont = widget.readingFont;
    _fontSize = widget.fontSize;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _apiKeyController.dispose();
    _contextPromptController.dispose();
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
              TextFormField(
                controller: _contextPromptController,
                decoration: const InputDecoration(
                  labelText: 'AI Context Prompt (optional)',
                  border: OutlineInputBorder(),
                  hintText:
                      'Additional context for AI (e.g., genre, style, themes)...',
                ),
                maxLines: 3,
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
              const DSSpacing.spacing16(),
              Row(
                children: [
                  const Expanded(flex: 1, child: DSText.bodyMedium('Theme')),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ThemeMode>(
                      initialValue: _themeMode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _themeMode = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const DSSpacing.spacing16(),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: DSText.bodyMedium('Reading Font'),
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ReadingFont>(
                      initialValue: _readingFont,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: ReadingFont.values
                          .map(
                            (font) => DropdownMenuItem(
                              value: font,
                              child: Text(font.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _readingFont = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const DSSpacing.spacing16(),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: DSText.bodyMedium('Font Size'),
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<double>(
                      initialValue: _fontSize,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 12.0, child: Text('12')),
                        DropdownMenuItem(value: 14.0, child: Text('14')),
                        DropdownMenuItem(value: 16.0, child: Text('16')),
                        DropdownMenuItem(value: 18.0, child: Text('18')),
                        DropdownMenuItem(value: 20.0, child: Text('20')),
                        DropdownMenuItem(value: 22.0, child: Text('22')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _fontSize = value;
                          });
                        }
                      },
                    ),
                  ),
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
                'contextPrompt': _contextPromptController.text,
                'themeMode': _themeMode,
                'readingFont': _readingFont,
                'fontSize': _fontSize,
              });
            }
          },
        ),
      ],
    );
  }
}
