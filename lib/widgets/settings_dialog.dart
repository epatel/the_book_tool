import 'package:the_book_tool/index.dart';

/// Per-backend AI configuration, as held while the dialog is open.
class AIBackendSettings {
  final String apiKey;
  final String apiUrl;
  final String model;

  const AIBackendSettings({
    required this.apiKey,
    required this.apiUrl,
    required this.model,
  });

  AIBackendSettings copyWith({String? apiKey, String? apiUrl, String? model}) {
    return AIBackendSettings(
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      model: model ?? this.model,
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final String name;
  final String author;
  final bool markdown;
  final String contextPrompt;
  final ThemeMode themeMode;
  final ReadingFont readingFont;
  final double fontSize;
  final String? ttsVoiceId;

  /// Which backend is active.
  final AIBackendKind backendKind;

  /// Saved settings for every backend, so switching tabs does not lose keys.
  final Map<AIBackendKind, AIBackendSettings> backends;

  /// Provider the sidecar should route to.
  final String sidecarProvider;

  const SettingsDialog({
    super.key,
    required this.name,
    required this.author,
    required this.markdown,
    this.contextPrompt = '',
    required this.themeMode,
    required this.readingFont,
    this.fontSize = 14.0,
    this.ttsVoiceId,
    required this.backendKind,
    required this.backends,
    this.sidecarProvider = defaultSidecarProvider,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _contextPromptController;

  // AI tab: one set of live controllers, swapped when the backend changes.
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiUrlController;
  late final TextEditingController _aiModelController;
  late final TextEditingController _sidecarProviderController;

  late AIBackendKind _backendKind;
  late Map<AIBackendKind, AIBackendSettings> _backends;

  // Result of the last "Test" press, for the current backend.
  AIBackendHealth? _health;
  bool _testing = false;

  /// Models discovered from a successful test, keyed by backend.
  final Map<AIBackendKind, List<String>> _discoveredModels = {};

  late bool _markdownEnabled;
  late ThemeMode _themeMode;
  late ReadingFont _readingFont;
  late double _fontSize;
  String? _ttsVoiceId;
  String? _ttsVoiceLocale;
  List<Map<String, String>> _availableVoices = [];
  bool _loadingVoices = true;
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _nameController = TextEditingController(text: widget.name);
    _authorController = TextEditingController(text: widget.author);
    _contextPromptController = TextEditingController(
      text: widget.contextPrompt,
    );

    _backendKind = widget.backendKind;
    _backends = {
      for (final kind in AIBackendKind.values)
        kind:
            widget.backends[kind] ??
            AIBackendSettings(
              apiKey: '',
              apiUrl: defaultUrlForBackend(kind),
              model: defaultModelForBackend(kind),
            ),
    };

    final active = _backends[_backendKind]!;
    _apiKeyController = TextEditingController(text: active.apiKey);
    _apiUrlController = TextEditingController(text: active.apiUrl);
    _aiModelController = TextEditingController(text: active.model);
    _sidecarProviderController = TextEditingController(
      text: widget.sidecarProvider,
    );

    _markdownEnabled = widget.markdown;
    _themeMode = widget.themeMode;
    _readingFont = widget.readingFont;
    _fontSize = widget.fontSize;
    _ttsVoiceId = widget.ttsVoiceId;

    _loadVoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _authorController.dispose();
    _contextPromptController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _aiModelController.dispose();
    _sidecarProviderController.dispose();
    super.dispose();
  }

  /// Snapshot the live controllers back into [_backends].
  void _stashCurrentBackend() {
    _backends[_backendKind] = AIBackendSettings(
      apiKey: _apiKeyController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      model: _aiModelController.text.trim(),
    );
  }

  void _switchBackend(AIBackendKind kind) {
    if (kind == _backendKind) return;

    _stashCurrentBackend();
    final next = _backends[kind]!;
    setState(() {
      _backendKind = kind;
      _apiKeyController.text = next.apiKey;
      _apiUrlController.text = next.apiUrl.isEmpty
          ? defaultUrlForBackend(kind)
          : next.apiUrl;
      _aiModelController.text = next.model.isEmpty
          ? defaultModelForBackend(kind)
          : next.model;
      _health = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _health = null;
    });

    final backend = AIService.buildBackend(
      kind: _backendKind,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _apiUrlController.text.trim(),
      sidecarProvider: _sidecarProviderController.text.trim(),
    );

    AIBackendHealth health;
    try {
      health = await backend.check();
    } catch (e) {
      health = AIBackendHealth(ok: false, message: e.toString());
    } finally {
      backend.dispose();
    }

    if (!mounted) return;
    setState(() {
      _testing = false;
      _health = health;
      if (health.ok && health.models.isNotEmpty) {
        _discoveredModels[_backendKind] = health.models;
      }
    });
  }

  /// Models to offer in the dropdown: whatever the last test found, else the
  /// compiled-in presets for this backend.
  List<String> get _modelChoices {
    final discovered = _discoveredModels[_backendKind];
    if (discovered != null && discovered.isNotEmpty) return discovered;
    return modelPresetsForBackend(_backendKind, _apiUrlController.text.trim());
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _ttsService.getEnhancedVoices();
      final savedLocale = await _ttsService.getVoiceLocale();
      if (mounted) {
        setState(() {
          _availableVoices = voices;
          _loadingVoices = false;
          _ttsVoiceLocale = savedLocale;

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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Settings'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 560,
          height: 560,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Book'),
                  Tab(text: 'AI'),
                  Tab(text: 'Reading'),
                ],
              ),
              const DSSpacing.spacing16(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildBookTab(), _buildAiTab(), _buildReadingTab()],
                ),
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
        DSButton.primary(label: 'Save', onPressed: _save),
      ],
    );
  }

  // --- Book tab ---------------------------------------------------------

  Widget _buildBookTab() {
    return SingleChildScrollView(
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
    );
  }

  // --- AI tab -----------------------------------------------------------

  Widget _buildAiTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<AIBackendKind>(
            initialValue: _backendKind,
            decoration: const InputDecoration(
              labelText: 'Backend',
              border: OutlineInputBorder(),
            ),
            items: AIBackendKind.values
                .map(
                  (kind) => DropdownMenuItem(
                    value: kind,
                    child: Text(kind.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _switchBackend(value);
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          DSText.bodySmall(
            _backendKind.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
          const DSSpacing.spacing16(),
          if (_backendKind.usesApiKey) ...[
            _buildApiKeyField(),
            const DSSpacing.spacing16(),
          ],
          _buildApiUrlField(),
          const DSSpacing.spacing16(),
          if (_backendKind == AIBackendKind.sidecar) ...[
            TextFormField(
              controller: _sidecarProviderController,
              decoration: const InputDecoration(
                labelText: 'Sidecar provider',
                border: OutlineInputBorder(),
                hintText: 'claude-agent-sdk',
                helperText: 'Which provider the sidecar should route to',
              ),
            ),
            const DSSpacing.spacing16(),
          ],
          _buildModelField(),
          const DSSpacing.spacing16(),
          _buildConnectionStatus(),
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
        ],
      ),
    );
  }

  Widget _buildApiKeyField() {
    final isSidecar = _backendKind == AIBackendKind.sidecar;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: switch (_backendKind) {
                AIBackendKind.openAiCompatible => 'OpenAI API Key',
                AIBackendKind.anthropic => 'Anthropic API Key',
                AIBackendKind.sidecar => 'Sidecar token (optional)',
              },
              border: const OutlineInputBorder(),
              hintText: switch (_backendKind) {
                AIBackendKind.openAiCompatible => 'sk-...',
                AIBackendKind.anthropic => 'sk-ant-...',
                AIBackendKind.sidecar => 'Bearer token, if you set one',
              },
            ),
            obscureText: true,
          ),
        ),
        if (!isSidecar) ...[
          SizedBox(width: AppTheme.spacing8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final uri = Uri.parse(switch (_backendKind) {
                  AIBackendKind.anthropic =>
                    'https://console.anthropic.com/settings/keys',
                  _ => 'https://platform.openai.com/api-keys',
                });
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              tooltip: 'Get API Key',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApiUrlField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: _backendKind == AIBackendKind.sidecar
                  ? 'Sidecar URL'
                  : 'API URL',
              border: const OutlineInputBorder(),
              hintText: defaultUrlForBackend(_backendKind),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Only the OpenAI-compatible backend has multiple known hosts.
        if (_backendKind == AIBackendKind.openAiCompatible) ...[
          SizedBox(width: AppTheme.spacing8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
              tooltip: 'Select provider',
              onSelected: (url) {
                setState(() {
                  _apiUrlController.text = url;
                  final models = getModelPresetsForUrl(url);
                  if (models.isNotEmpty) {
                    _aiModelController.text = models.first;
                  }
                  _health = null;
                });
              },
              itemBuilder: (context) => apiUrlPresets.entries
                  .map(
                    (entry) => PopupMenuItem<String>(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModelField() {
    final models = _modelChoices;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _aiModelController,
            decoration: InputDecoration(
              labelText: 'AI Model',
              border: const OutlineInputBorder(),
              hintText: 'e.g. ${defaultModelForBackend(_backendKind)}',
            ),
          ),
        ),
        SizedBox(width: AppTheme.spacing8),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down_circle_outlined),
            tooltip: models.isEmpty
                ? 'Press Test to discover models'
                : 'Select model',
            enabled: models.isNotEmpty,
            onSelected: (model) {
              setState(() {
                _aiModelController.text = model;
              });
            },
            itemBuilder: (context) => models
                .map(
                  (model) =>
                      PopupMenuItem<String>(value: model, child: Text(model)),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final scheme = Theme.of(context).colorScheme;
    final health = _health;

    final Color color;
    final IconData icon;
    final String label;

    if (_testing) {
      color = scheme.onSurface.withValues(alpha: 0.6);
      icon = Icons.circle_outlined;
      label = 'Testing...';
    } else if (health == null) {
      color = scheme.onSurface.withValues(alpha: 0.6);
      icon = Icons.circle_outlined;
      label = 'Not tested';
    } else if (health.ok) {
      color = scheme.primary;
      icon = Icons.check_circle;
      label = health.message;
    } else {
      color = scheme.error;
      icon = Icons.error_outline;
      label = health.message;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: DSText.bodySmall(label, style: TextStyle(color: color)),
        ),
        const SizedBox(width: AppTheme.spacing8),
        DSButton.text(
          label: 'Test',
          onPressed: _testing ? null : _testConnection,
        ),
      ],
    );
  }

  // --- Reading tab ------------------------------------------------------

  Widget _buildReadingTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              const Expanded(flex: 1, child: DSText.bodyMedium('Reading Font')),
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
              const Expanded(flex: 1, child: DSText.bodyMedium('Font Size')),
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
    );
  }

  // --- Save -------------------------------------------------------------

  /// Flags key/URL pairings that are almost certainly a mistake.
  List<String> _configWarnings() {
    final warnings = <String>[];
    final apiKey = _apiKeyController.text.trim();
    final apiUrl = _apiUrlController.text.trim();

    switch (_backendKind) {
      case AIBackendKind.openAiCompatible:
        final isOpenRouter = apiUrl.contains('openrouter.ai');
        final isOpenAI = apiUrl.contains('api.openai.com');

        if (apiKey.isEmpty) {
          if (apiUrl != defaultApiUrl) {
            warnings.add('You have set a custom API URL but no API key.');
          }
          break;
        }
        if (apiKey.startsWith('sk-ant-')) {
          warnings.add(
            'That looks like an Anthropic key. Switch the backend to '
            '"Anthropic API" to use it.',
          );
        }
        if (apiKey.startsWith('sk-or-') && !isOpenRouter) {
          warnings.add(
            'Your API key looks like an OpenRouter key (sk-or-...) but the URL is not OpenRouter.',
          );
        }
        if (isOpenRouter && !apiKey.startsWith('sk-or-')) {
          warnings.add(
            'The URL is OpenRouter but your key does not start with sk-or-.',
          );
        }
        if (apiKey.startsWith('sk-proj-') && !isOpenAI) {
          warnings.add(
            'Your API key looks like an OpenAI project key (sk-proj-...) but the URL is not OpenAI.',
          );
        }
        if (apiKey.length < 20) {
          warnings.add('Your API key seems suspiciously short.');
        }

      case AIBackendKind.anthropic:
        if (apiKey.isEmpty) {
          warnings.add('The Anthropic backend needs an API key.');
          break;
        }
        if (!apiKey.startsWith('sk-ant-')) {
          warnings.add('Anthropic keys normally start with sk-ant-.');
        }
        if (!_aiModelController.text.trim().startsWith('claude-')) {
          warnings.add(
            'The Anthropic backend only serves Claude models; '
            '"${_aiModelController.text.trim()}" will not resolve.',
          );
        }

      case AIBackendKind.sidecar:
        if (!apiUrl.startsWith('http://') && !apiUrl.startsWith('https://')) {
          warnings.add('The sidecar URL should start with http:// or https://.');
        }
        if (_health == null) {
          warnings.add(
            'The sidecar has not been tested. AI features will fail if it is '
            'not running.',
          );
        } else if (!_health!.ok) {
          warnings.add('The last sidecar test failed: ${_health!.message}');
        }
    }

    return warnings;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final warnings = _configWarnings();
    if (warnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const DSText.titleMedium('Configuration Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in warnings) ...[
                DSText.bodyMedium('• $w'),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              const DSText.bodySmall('Save anyway?'),
            ],
          ),
          actions: [
            DSButton.text(
              label: 'Go Back',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            DSButton.primary(
              label: 'Save Anyway',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    _stashCurrentBackend();

    if (!mounted) return;
    Navigator.of(context).pop({
      'name': _nameController.text,
      'author': _authorController.text,
      'markdown': _markdownEnabled,
      'contextPrompt': _contextPromptController.text,
      'themeMode': _themeMode,
      'readingFont': _readingFont,
      'fontSize': _fontSize,
      'ttsVoiceId': _ttsVoiceId,
      'ttsVoiceLocale': _ttsVoiceLocale,
      'backendKind': _backendKind,
      'backends': _backends,
      'sidecarProvider': _sidecarProviderController.text.trim(),
    });
  }
}
