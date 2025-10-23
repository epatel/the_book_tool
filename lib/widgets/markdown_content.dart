import 'package:the_book_tool/index.dart';

/// A reusable widget for rendering markdown content with consistent styling
class MarkdownContent extends StatelessWidget {
  final String data;
  final ReadingFont readingFont;
  final double fontSize;
  final bool collapsed;
  final double? collapsedHeight;
  final bool showGradientOverlay;

  const MarkdownContent({
    super.key,
    required this.data,
    required this.readingFont,
    required this.fontSize,
    this.collapsed = false,
    this.collapsedHeight,
    this.showGradientOverlay = false,
  });

  /// Builds a consistent MarkdownStyleSheet for the app
  static MarkdownStyleSheet buildStyleSheet(
    BuildContext context,
    ReadingFont readingFont,
    double fontSize,
  ) {
    return MarkdownStyleSheet(
      p: readingFont.getTextStyle(
        fontSize: fontSize,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      code: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: fontSize * 0.9,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markdownBody = MarkdownBody(
      data: data,
      fitContent: false,
      selectable: true,
      sizedImageBuilder: (config) => MarkdownAssetImageBuilder(
        uri: config.uri,
        title: config.title,
        altText: config.alt,
        width: config.width,
        height: config.height,
      ),
      styleSheet: buildStyleSheet(context, readingFont, fontSize),
    );

    if (collapsed) {
      if (showGradientOverlay) {
        return SizedBox(
          height: collapsedHeight ?? AppTheme.collapsedContentHeight,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: markdownBody,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: AppTheme.gradientOverlayHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface.withValues(
                              alpha: 0.0,
                            ),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: collapsedHeight ?? AppTheme.collapsedContentHeight,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: markdownBody,
        ),
      );
    }

    return markdownBody;
  }
}
