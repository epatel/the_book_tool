import 'package:the_book_tool/index.dart';

/// Widget that displays text with inline image support
/// Supports markdown image syntax: ![description](alias) or ![description](alias "width=50% align=center")
class TextWithImages extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TextWithImages({
    super.key,
    required this.text,
    this.style,
  });

  /// Parses the title string for width and alignment specifications
  _ImageSpec _parseTitle(String? title) {
    if (title == null || title.isEmpty) {
      return _ImageSpec();
    }

    double? widthFraction;
    Alignment alignment = Alignment.center;

    // Parse width parameter
    final widthMatch = RegExp(r'width=([^\s]+)').firstMatch(title);
    if (widthMatch != null) {
      final widthValue = widthMatch.group(1)!;

      if (widthValue.endsWith('%')) {
        // Percentage: "50%" -> 0.5
        final percent = double.tryParse(widthValue.replaceAll('%', ''));
        if (percent != null && percent > 0 && percent <= 100) {
          widthFraction = percent / 100;
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
    final alignMatch = RegExp(r'align=([^\s]+)').firstMatch(title);
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

    return _ImageSpec(widthFraction: widthFraction, alignment: alignment);
  }

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService();

    // Parse the text for markdown image syntax with surrounding newlines
    // Pattern captures optional leading/trailing newlines around the image tag
    final pattern = RegExp(
      r'\n*!\[([^\]]*)\]\(([^\s)]+)(?:\s+"([^"]+)")?\)\n*',
    );
    final matches = pattern.allMatches(text);

    if (matches.isEmpty) {
      // No images found, return plain text
      return Text(text, style: style);
    }

    // Build a list of widgets (text spans and images)
    final List<Widget> widgets = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the image tag
      if (match.start > lastEnd) {
        var textBefore = text.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          widgets.add(
            Text(
              textBefore,
              style: style,
            ),
          );
        }
      }

      // Extract image components
      // ignore: unused_local_variable
      final description = match.group(1) ?? '';
      final alias = match.group(2)!;
      final title = match.group(3);

      // Parse width and alignment parameters
      final spec = _parseTitle(title);

      // Add image widget with minimal spacing
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: Sizes.imageTopSpacing,
            bottom: Sizes.imageBottomSpacing,
          ),
          child: FutureBuilder<Asset?>(
            future: assetService.getAssetByAlias(alias),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildPlaceholder(context, alias, spec, isLoading: true);
              }

              final asset = snapshot.data;
              if (asset != null && asset.isImage) {
                Widget imageWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Image.memory(
                    asset.fileData,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(
                        context,
                        alias,
                        spec,
                        isError: true,
                      );
                    },
                  ),
                );

                // Apply width and alignment if specified
                if (spec.widthFraction != null) {
                  imageWidget = Align(
                    alignment: spec.alignment,
                    child: FractionallySizedBox(
                      widthFactor: spec.widthFraction,
                      child: imageWidget,
                    ),
                  );
                }

                return imageWidget;
              }

              // Asset not found
              return _buildPlaceholder(context, alias, spec);
            },
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after the last image
    if (lastEnd < text.length) {
      var textAfter = text.substring(lastEnd);
      if (textAfter.isNotEmpty) {
        widgets.add(
          Text(
            textAfter,
            style: style,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 0,
      children: widgets,
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    String alias,
    _ImageSpec spec, {
    bool isLoading = false,
    bool isError = false,
  }) {
    Widget placeholder = Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.broken_image : Icons.image_not_supported,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const DSSpacing.spacing8(),
                  DSText.bodySmall(
                    isError
                        ? 'Error loading image'
                        : 'Image not found: "$alias"',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );

    // Apply width and alignment if specified
    if (spec.widthFraction != null) {
      placeholder = Align(
        alignment: spec.alignment,
        child: FractionallySizedBox(
          widthFactor: spec.widthFraction,
          child: placeholder,
        ),
      );
    }

    return placeholder;
  }
}

/// Helper class to hold parsed image specifications
class _ImageSpec {
  final double? widthFraction; // 0.0 to 1.0 for fractional widths
  final Alignment alignment; // Image alignment

  _ImageSpec({
    this.widthFraction,
    this.alignment = Alignment.center,
  });
}
