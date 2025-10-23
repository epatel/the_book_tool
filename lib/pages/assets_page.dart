import 'dart:typed_data';

import 'package:the_book_tool/index.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssetProvider>(context, listen: false).loadAssets();
    });
  }

  Future<void> _pickAndAddFile() async {
    const XTypeGroup imageGroup = XTypeGroup(
      label: 'Images',
      extensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'svg',
        'tiff',
        'tif',
        'ico',
        'heic',
        'heif',
      ],
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: [
        imageGroup,
      ],
    );

    if (file != null) {
      await _addFile(file);
    }
  }

  Future<void> _addFile(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name;
      // Use FileTypeService to identify MIME type
      final mimeType = FileTypeService.identifyMimeType(bytes, filename);

      if (!mounted) return;

      // Only show ImportAssetDialog for images
      if (FileTypeService.isImage(mimeType)) {
        // Show import dialog with crop and resolution options
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dialogContext) => ImportAssetDialog(
            imageData: bytes,
            filename: filename,
          ),
        );

        if (result != null && mounted) {
          final alias = result['alias'] as String;
          final processedImageData = result['imageData'] as Uint8List;
          final isPng = result['isPng'] as bool;

          // Determine final MIME type based on actual saved format
          final finalMimeType = isPng ? 'image/png' : 'image/jpeg';

          // Generate thumbnail
          final thumbnail = await ThumbnailService.generateThumbnail(
            processedImageData,
          );

          if (mounted) {
            await Provider.of<AssetProvider>(context, listen: false).addAsset(
              filename,
              alias,
              finalMimeType,
              processedImageData,
              thumbnail: thumbnail,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $filename'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } else {
        // For non-images, use the simple alias dialog
        final alias = await showDialog<String>(
          context: context,
          builder: (dialogContext) => _AliasInputDialog(filename: filename),
        );

        if (alias != null && alias.isNotEmpty && mounted) {
          await Provider.of<AssetProvider>(context, listen: false).addAsset(
            filename,
            alias,
            mimeType,
            bytes,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $filename'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditAssetDialog(Asset asset) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditAssetDialog(asset: asset),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<AssetProvider>(
          context,
          listen: false,
        ).deleteAsset(asset.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final updatedAsset = asset.copyWith(
          alias: result['alias'] as String,
        );
        await Provider.of<AssetProvider>(
          context,
          listen: false,
        ).updateAsset(updatedAsset);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getIconForFileType(String mimeType) {
    if (FileTypeService.isImage(mimeType)) {
      return Icons.image;
    } else if (FileTypeService.isDocument(mimeType)) {
      return Icons.description;
    } else if (FileTypeService.isAudio(mimeType)) {
      return Icons.audiotrack;
    } else if (FileTypeService.isVideo(mimeType)) {
      return Icons.videocam;
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DSAppBar(
          title: 'Assets',
          titleActions: [
            IconButton(
              icon: const DSAddIcon(),
              tooltip: 'Add Asset',
              onPressed: _pickAndAddFile,
            ),
          ],
        ),
        Expanded(
          child: DropTarget(
            onDragEntered: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onDragExited: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            onDragDone: (details) async {
              setState(() {
                _isDragging = false;
              });

              // Filter for image files only
              final imageExtensions = [
                'jpg',
                'jpeg',
                'png',
                'gif',
                'webp',
                'bmp',
                'svg',
                'tiff',
                'tif',
                'ico',
                'heic',
                'heif',
              ];

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              int skippedFiles = 0;
              for (final file in details.files) {
                final extension = file.name.split('.').last.toLowerCase();
                if (imageExtensions.contains(extension)) {
                  await _addFile(file);
                } else {
                  skippedFiles++;
                }
              }

              // Show message if non-image files were dropped
              if (skippedFiles > 0 && mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Skipped $skippedFiles non-image file${skippedFiles > 1 ? 's' : ''}. Only images are allowed.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Consumer<AssetProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.assets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const DSSpacing.spacing16(),
                            DSText.bodyLarge(
                              'No assets yet',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const DSSpacing.spacing8(),
                            DSText.bodySmall(
                              'Drag and drop images here or tap the + button',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: provider.assets.length,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final assets = List<Asset>.from(provider.assets);
                        final asset = assets.removeAt(oldIndex);
                        assets.insert(newIndex, asset);
                        Provider.of<AssetProvider>(
                          context,
                          listen: false,
                        ).reorderAssets(assets);
                      },
                      itemBuilder: (context, index) {
                        final asset = provider.assets[index];
                        return SizedBox(
                          key: ValueKey(asset.id),
                          width: double.infinity,
                          child: DSCard(
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                    child: asset.isImage
                                        ? Image.memory(
                                            asset.hasThumbnail
                                                ? asset.thumbnail!
                                                : asset.fileData,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            _getIconForFileType(asset.mimeType),
                                            size: 40,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                  ),
                                ),
                                const DSSpacing.spacing16(),
                                // File info
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showEditAssetDialog(asset),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DSText.titleMedium(asset.alias),
                                        const DSSpacing.spacing4(),
                                        DSText.bodySmall(
                                          asset.filename,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const DSSpacing.spacing4(),
                                        DSText.bodySmall(
                                          _formatFileSize(asset.fileSize),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  iconSize: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.7),
                                  onPressed: () => _showEditAssetDialog(asset),
                                  tooltip: 'Edit Asset',
                                ),
                                SizedBox(width: AppTheme.spacing24),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Drag overlay
                if (_isDragging)
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const DSSpacing.spacing16(),
                            DSText.titleLarge(
                              'Drop images here',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AliasInputDialog extends StatefulWidget {
  final String filename;

  const _AliasInputDialog({required this.filename});

  @override
  State<_AliasInputDialog> createState() => _AliasInputDialogState();
}

class _AliasInputDialogState extends State<_AliasInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Use filename without extension as default alias
    final lastDot = widget.filename.lastIndexOf('.');
    final defaultAlias = lastDot > 0
        ? widget.filename.substring(0, lastDot)
        : widget.filename;
    _controller = TextEditingController(text: defaultAlias);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Enter Asset Alias'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText.bodyMedium(
            'This alias will be used to reference the asset in your chapters.',
          ),
          const DSSpacing.spacing16(),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Alias',
              hintText: 'e.g., hero_portrait',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final alias = _controller.text.trim();
            if (alias.isNotEmpty) {
              Navigator.of(context).pop(alias);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
