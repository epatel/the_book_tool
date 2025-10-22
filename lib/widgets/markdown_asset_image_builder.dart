import 'package:the_book_tool/index.dart';

/// Custom image builder for MarkdownBody that resolves asset aliases
/// Supports syntax: ![description](asset_alias)
/// Width control: ![description](asset_alias "width=50%")
/// Alignment: ![description](asset_alias "width=50% align=center")
class MarkdownAssetImageBuilder extends StatelessWidget {
  final Uri uri;
  final String? title;
  final String? altText;
  final double? width;
  final double? height;

  const MarkdownAssetImageBuilder({
    super.key,
    required this.uri,
    this.title,
    this.altText,
    this.width,
    this.height,
  });

  /// Parses the title string for width and alignment specifications
  _ImageSizeSpec _parseTitle() {
    if (title == null || title!.isEmpty) {
      return _ImageSizeSpec();
    }

    double? widthFraction;
    double? widthPixels;
    Alignment alignment = Alignment.center;

    // Parse width parameter
    final widthMatch = RegExp(r'width=([^\s]+)').firstMatch(title!);
    if (widthMatch != null) {
      final widthValue = widthMatch.group(1)!;

      if (widthValue.endsWith('%')) {
        // Percentage: "50%" -> 0.5
        final percent = double.tryParse(widthValue.replaceAll('%', ''));
        if (percent != null && percent > 0 && percent <= 100) {
          widthFraction = percent / 100;
        }
      } else if (widthValue.endsWith('px')) {
        // Pixels: "300px" -> 300.0
        final pixels = double.tryParse(widthValue.replaceAll('px', ''));
        if (pixels != null && pixels > 0) {
          widthPixels = pixels;
        }
      } else if (widthValue == 'small') {
        widthFraction = 0.25;
      } else if (widthValue == 'medium') {
        widthFraction = 0.5;
      } else if (widthValue == 'large') {
        widthFraction = 0.75;
      } else {
        // Fraction: "0.5" -> 0.5
        final fraction = double.tryParse(widthValue);
        if (fraction != null && fraction > 0 && fraction <= 1) {
          widthFraction = fraction;
        }
      }
    }

    // Parse align parameter
    final alignMatch = RegExp(r'align=([^\s]+)').firstMatch(title!);
    if (alignMatch != null) {
      final alignValue = alignMatch.group(1)!.toLowerCase();
      switch (alignValue) {
        case 'left':
          alignment = Alignment.centerLeft;
          break;
        case 'right':
          alignment = Alignment.centerRight;
          break;
        case 'center':
          alignment = Alignment.center;
          break;
      }
    }

    return _ImageSizeSpec(
      widthFraction: widthFraction,
      widthPixels: widthPixels,
      alignment: alignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService();
    final alias = uri.toString();
    final sizeSpec = _parseTitle();

    return FutureBuilder<Asset?>(
      future: assetService.getAssetByAlias(alias),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrapWithSize(
            _buildLoadingPlaceholder(context),
            sizeSpec,
          );
        }

        if (snapshot.hasError) {
          return _wrapWithSize(
            _buildErrorPlaceholder(context),
            sizeSpec,
          );
        }

        final asset = snapshot.data;

        if (asset != null && asset.isImage) {
          // Asset found and it's an image - display it
          return _wrapWithSize(
            _buildImageWidget(
              context,
              Image.memory(
                asset.fileData,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder(context, 'Invalid image');
                },
              ),
            ),
            sizeSpec,
          );
        }

        // No matching asset or not an image - try default image handling
        if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
          return _wrapWithSize(
            _buildImageWidget(
              context,
              Image.network(
                uri.toString(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildNotFoundPlaceholder(context, alias);
                },
              ),
            ),
            sizeSpec,
          );
        }

        // Asset not found - show placeholder
        return _wrapWithSize(
          _buildNotFoundPlaceholder(context, alias),
          sizeSpec,
        );
      },
    );
  }

  /// Wraps a widget with appropriate sizing and alignment based on spec
  Widget _wrapWithSize(Widget child, _ImageSizeSpec spec) {
    Widget sized = child;

    // Apply width constraints
    if (spec.widthPixels != null) {
      // Fixed pixel width
      sized = SizedBox(width: spec.widthPixels, child: sized);
    } else if (spec.widthFraction != null) {
      // Fractional width
      sized = FractionallySizedBox(
        widthFactor: spec.widthFraction,
        child: sized,
      );
    }

    // Apply alignment if width is constrained
    if (spec.widthPixels != null || spec.widthFraction != null) {
      sized = Align(
        alignment: spec.alignment,
        child: sized,
      );
    }

    return sized;
  }

  Widget _buildImageWidget(BuildContext context, Widget image) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: image,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context, [String? message]) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message == 'Invalid image'
                  ? Icons.broken_image
                  : Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 48,
            ),
            const DSSpacing.spacing8(),
            DSText.bodySmall(
              message ?? 'Error loading image',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundPlaceholder(BuildContext context, String alias) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 48,
            ),
            const DSSpacing.spacing8(),
            DSText.bodySmall(
              'Asset not found: "$alias"',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const DSSpacing.spacing4(),
            DSText.bodySmall(
              'Check Assets section',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to hold parsed image size specifications
class _ImageSizeSpec {
  final double? widthFraction; // 0.0 to 1.0 for percentage widths
  final double? widthPixels; // Fixed pixel width
  final Alignment alignment; // Image alignment

  _ImageSizeSpec({
    this.widthFraction,
    this.widthPixels,
    this.alignment = Alignment.center,
  });
}
