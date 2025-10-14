import 'package:the_book_tool/index.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditCharacterDialog extends StatefulWidget {
  final Character character;
  final bool hasApiKey;

  const EditCharacterDialog({
    super.key,
    required this.character,
    this.hasApiKey = false,
  });

  @override
  State<EditCharacterDialog> createState() => _EditCharacterDialogState();
}

class _EditCharacterDialogState extends State<EditCharacterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _aiPromptController;
  bool _showAiPrompt = false;
  bool _isLoadingAi = false;
  bool _enableCommands = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _descriptionController = TextEditingController(
      text: widget.character.description,
    );
    _aiPromptController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
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
        title: const DSText.titleLarge('Delete Character'),
        content: const DSText.bodyMedium(
          'Are you sure you want to delete this character? This action cannot be undone.',
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
      if (_formKey.currentState!.validate()) {
        Navigator.of(context).pop({
          'name': _nameController.text,
          'description': _descriptionController.text,
        });
      }
      return;
    }

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final bookDataService = BookDataService();
      final bookData = await bookDataService.collectAllBookData();

      final context = {
        'currentItem': {
          'type': 'character',
          'id': widget.character.id,
          'name': _nameController.text,
          'description': _descriptionController.text,
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
        // Handle text response
        else if (response.hasText) {
          setState(() {
            _descriptionController.text = response.text!;
          });
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
      title: const DSText.titleLarge('Edit Character'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const DSSpacing.spacing16(),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
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
                        decoration: const InputDecoration(
                          labelText: 'AI Prompt',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your prompt...',
                        ),
                        maxLines: 2,
                        enabled: !_isLoadingAi,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing8),
                    if (_isLoadingAi)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendAiPrompt,
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
                    'name': _nameController.text,
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
