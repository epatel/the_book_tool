import 'package:the_book_tool/index.dart';

/// A design system loading indicator.
class DSLoading extends StatelessWidget {
  final double? size;
  final double strokeWidth;

  const DSLoading({
    super.key,
    this.size,
    this.strokeWidth = AppTheme.strokeWidthNormal,
  });

  /// A small loading indicator for compact spaces.
  const DSLoading.small({
    super.key,
    this.strokeWidth = AppTheme.strokeWidthThin,
  }) : size = AppTheme.iconSizeMedium;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(strokeWidth: strokeWidth);

    if (size != null) {
      return SizedBox(width: size, height: size, child: indicator);
    }

    return indicator;
  }
}

/// A centered loading indicator for pages.
class DSLoadingCenter extends StatelessWidget {
  const DSLoadingCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: DSLoading());
  }
}
