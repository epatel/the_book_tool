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
  final String? ttsVoiceId;
  final String aiModel;

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
    this.ttsVoiceId,
    this.aiModel = 'gpt-5.2',
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
  String? _ttsVoiceId;
  late String _aiModel;
  String? _ttsVoiceLocale;
  List<Map<String, String>> _availableVoices = [];
  bool _loadingVoices = true;
  final TtsService _ttsService = TtsService();

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
    _ttsVoiceId = widget.ttsVoiceId;
    _aiModel = widget.aiModel;

    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _ttsService.getEnhancedVoices();
      // Also load the saved locale
      final savedLocale = await _ttsService.getVoiceLocale();
      if (mounted) {
        setState(() {
          _availableVoices = voices;
          _loadingVoices = false;
          _ttsVoiceLocale = savedLocale;

          // If no voice selected yet, select first available
          if (_ttsVoiceId == null && voices.isNotEmpty) {
            _ttsVoiceId = voices.first['name'];
            _ttsVoiceLocale = voices.first['locale'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading voices: $e');
      if (mounted) {
        setState(() {
          _loadingVoices = false;
        });
      }
    }
  }

  Future<void> _previewVoice() async {
    if (_ttsVoiceId != null && _ttsVoiceLocale != null) {
      await _ttsService.setVoiceId(_ttsVoiceId!, _ttsVoiceLocale!);
      await _ttsService.speak('This is a preview of the selected voice.');
    }
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: SingleChildScrollView(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'OpenAI API Key',
                        border: OutlineInputBorder(),
                        hintText: 'sk-...',
                      ),
                      obscureText: true,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://platform.openai.com/api-keys',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      tooltip: 'Get API Key',
                    ),
                  ),
                ],
              ),
              const DSSpacing.spacing16(),
              Row(
                children: [
                  const Expanded(flex: 1, child: DSText.bodyMedium('AI Model')),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _aiModel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: modelPricing.keys
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _aiModel = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
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
              const DSSpacing.spacing16(),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DSText.bodyMedium('TTS Voice'),
                        const SizedBox(width: 4),
                        Tooltip(
                          message:
                              'Only enhanced and premium quality voices are available for text-to-speech',
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _loadingVoices
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _availableVoices.isEmpty
                        ? DSText.bodySmall(
                            'No enhanced/premium voices available',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _ttsVoiceId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _availableVoices
                                      .map(
                                        (voice) => DropdownMenuItem(
                                          value: voice['name'],
                                          child: Text(
                                            '${voice['name']} (${voice['locale']})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      // Find the matching voice to get its locale
                                      final voice = _availableVoices.firstWhere(
                                        (v) => v['name'] == value,
                                      );
                                      setState(() {
                                        _ttsVoiceId = value;
                                        _ttsVoiceLocale = voice['locale'];
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: AppTheme.spacing8),
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: _ttsVoiceId == null
                                    ? null
                                    : _previewVoice,
                                tooltip: 'Preview',
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              ],
            ),
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
                'ttsVoiceId': _ttsVoiceId,
                'ttsVoiceLocale': _ttsVoiceLocale,
                'aiModel': _aiModel,
              });
            }
          },
        ),
      ],
    );
  }
}
