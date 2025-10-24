import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:the_book_tool/index.dart';
import 'package:crop_image/crop_image.dart';
import 'package:image/image.dart' as img;

class ImportAssetDialog extends StatefulWidget {
  final Uint8List imageData;
  final String filename;

  const ImportAssetDialog({
    super.key,
    required this.imageData,
    required this.filename,
  });

  @override
  State<ImportAssetDialog> createState() => _ImportAssetDialogState();
}

class _ImportAssetDialogState extends State<ImportAssetDialog> {
  final TextEditingController _aliasController = TextEditingController();
  late CropController _cropController;

  Uint8List? _croppedImage;
  int _maxWidth = 1920; // Default max width
  int _quality = 85; // JPG quality (0-100)
  bool _isPng = false;
  int _cropKey = 0; // Used to force CropImage widget rebuild
  int? _imageWidth; // Current image width
  int? _imageHeight; // Current image height
  bool _showPreview = false; // Show preview without crop overlay

  @override
  void initState() {
    super.initState();

    // Determine default format from filename, but allow user to change it
    _isPng = widget.filename.toLowerCase().endsWith('.png');

    // Set default alias from filename
    final nameWithoutExtension = widget.filename.split('.').first;
    _aliasController.text = nameWithoutExtension;

    // Load image dimensions
    _loadImageDimensions(widget.imageData);

    // Initialize crop controller
    _initializeCropController();
  }

  void _loadImageDimensions(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      if (image != null) {
        setState(() {
          _imageWidth = image.width;
          _imageHeight = image.height;
          // Calculate valid range
          final minWidth = (image.width / 4).clamp(100, 640).toInt();
          final maxWidth = image.width;
          // Clamp _maxWidth to valid range
          _maxWidth = _maxWidth.clamp(minWidth, maxWidth);
        });
      }
    } catch (e) {
      // If decoding fails, use defaults
    }
  }

  void _initializeCropController() {
    _cropController = CropController(
      aspectRatio: null, // Free aspect ratio
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _onCropPressed() async {
    final croppedImage = await _cropController.croppedBitmap();
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData != null) {
      final croppedBytes = byteData.buffer.asUint8List();

      // Load dimensions of the cropped image
      _loadImageDimensions(croppedBytes);

      setState(() {
        _croppedImage = croppedBytes;
        // Increment key to force widget rebuild
        _cropKey++;
      });

      // Dispose old controller and create new one after setState
      _cropController.dispose();
      _initializeCropController();
    }
  }

  Future<Uint8List> _processImage() async {
    // Use cropped image if available, otherwise use original
    final imageData = _croppedImage ?? widget.imageData;

    // Decode the image
    img.Image? image = img.decodeImage(imageData);
    if (image == null) {
      return imageData; // Return original if decoding fails
    }

    // Resize if necessary
    if (image.width > _maxWidth) {
      final aspectRatio = image.height / image.width;
      final newHeight = (_maxWidth * aspectRatio).round();
      image = img.copyResize(image, width: _maxWidth, height: newHeight);
    }

    // Encode based on format
    if (_isPng) {
      return Uint8List.fromList(img.encodePng(image));
    } else {
      return Uint8List.fromList(img.encodeJpg(image, quality: _quality));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('Import Asset'),
      content: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alias field
            TextFormField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias',
                border: OutlineInputBorder(),
                hintText: 'Enter a unique alias for this asset',
              ),
            ),
            const DSSpacing.spacing16(),

            // Format selector
            Row(
              children: [
                const DSText.bodyMedium('Output Format:'),
                const SizedBox(width: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('JPG'),
                      icon: Icon(Icons.photo, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('PNG'),
                      icon: Icon(Icons.image, size: 18),
                    ),
                  ],
                  selected: {_isPng},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _isPng = selection.first;
                    });
                  },
                ),
              ],
            ),
            const DSSpacing.spacing16(),

            // Resolution slider
            if (_imageWidth != null) ...[
              Builder(
                builder: (context) {
                  final minWidth = (_imageWidth! / 4)
                      .clamp(100, 640)
                      .toDouble();
                  final maxWidth = _imageWidth!.toDouble();
                  final clampedValue = _maxWidth.toDouble().clamp(
                    minWidth,
                    maxWidth,
                  );

                  return Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: DSText.bodyMedium('Max Width:'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: clampedValue,
                                min: minWidth,
                                max: maxWidth,
                                divisions: ((maxWidth - minWidth) / 100)
                                    .clamp(1, 32)
                                    .toInt(),
                                label: '${clampedValue.toInt()} px',
                                onChanged: (value) {
                                  setState(() {
                                    _maxWidth = value.toInt();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: DSText.bodySmall(
                                '${clampedValue.toInt()} / $_imageWidth px',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const DSSpacing.spacing4(),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: DSText.bodySmall(
                  'Current resolution: $_imageWidth × $_imageHeight px',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],

            // Quality slider (only for JPG)
            if (!_isPng) ...[
              const DSSpacing.spacing8(),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: DSText.bodyMedium('Quality:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _quality.toDouble(),
                            min: 50,
                            max: 100,
                            divisions: 10,
                            label: '$_quality%',
                            onChanged: (value) {
                              setState(() {
                                _quality = value.toInt();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: DSText.bodySmall('$_quality%'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const DSSpacing.spacing16(),

            // Crop preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: _showPreview
                      ? Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Center(
                            child: Image.memory(
                              _croppedImage ?? widget.imageData,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : CropImage(
                          key: ValueKey(_cropKey),
                          controller: _cropController,
                          image: Image.memory(
                            _croppedImage ?? widget.imageData,
                          ),
                          paddingSize: 25.0,
                          alwaysMove: true,
                        ),
                ),
              ),
            ),
            const DSSpacing.spacing16(),

            // Crop button
            Center(
              child: DSButton.text(
                label: _croppedImage == null ? 'Crop Image' : 'Crop Again',
                onPressed: _onCropPressed,
              ),
            ),
          ],
        ),
      ),
      actions: [
        DSButton.text(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _showPreview = true),
          onExit: (_) => setState(() => _showPreview = false),
          child: DSButton.primary(
            label: 'Import',
            onPressed: _aliasController.text.isEmpty
                ? null
                : () async {
                    final processedImage = await _processImage();
                    if (context.mounted) {
                      Navigator.of(context).pop({
                        'alias': _aliasController.text,
                        'imageData': processedImage,
                        'isPng': _isPng, // Return the selected format
                      });
                    }
                  },
          ),
        ),
      ],
    );
  }
}
