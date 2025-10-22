import 'package:the_book_tool/index.dart';

class EditAssetDialog extends StatefulWidget {
  final Asset asset;

  const EditAssetDialog({
    super.key,
    required this.asset,
  });

  @override
  State<EditAssetDialog> createState() => _EditAssetDialogState();
}

class _EditAssetDialogState extends State<EditAssetDialog> {
  late final TextEditingController _aliasController;
  late String _originalAlias;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _originalAlias = widget.asset.alias;
    _aliasController = TextEditingController(text: widget.asset.alias);
    _aliasController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _aliasController.text.trim() != _originalAlias.trim();

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  bool get _canSave => _hasChanges && _aliasController.text.trim().isNotEmpty;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const DSText.titleLarge('Delete Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DSText.bodyMedium(
              'Are you sure you want to delete this asset?',
            ),
            const DSSpacing.spacing16(),
            DSText.bodyMedium(
              'Asset: ${widget.asset.alias}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const DSSpacing.spacing16(),
            DSText.bodySmall(
              'This action cannot be undone. Any references to this asset in your chapters will no longer work.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop({'delete': true});
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Edit Asset'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              if (widget.asset.isImage) ...[
                Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Image.memory(
                        widget.asset.fileData,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const DSSpacing.spacing16(),
              ],

              // Filename
              DSText.labelLarge('Filename'),
              const DSSpacing.spacing4(),
              DSText.bodyMedium(
                widget.asset.filename,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const DSSpacing.spacing16(),

              // File size
              DSText.labelLarge('File Size'),
              const DSSpacing.spacing4(),
              DSText.bodyMedium(
                _formatFileSize(widget.asset.fileSize),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const DSSpacing.spacing16(),

              // File type
              DSText.labelLarge('Type'),
              const DSSpacing.spacing4(),
              DSText.bodyMedium(
                '${FileTypeService.getFileTypeDescription(widget.asset.mimeType)} (${widget.asset.mimeType})',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const DSSpacing.spacing16(),

              // Alias (editable)
              DSText.labelLarge('Alias'),
              const DSSpacing.spacing4(),
              TextField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  hintText: 'Enter asset alias',
                  helperText:
                      'Use this name to reference the asset in your chapters',
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirmDelete,
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSave
              ? () {
                  Navigator.of(context).pop({
                    'alias': _aliasController.text.trim(),
                  });
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
