import 'package:the_book_tool/index.dart';

class DSText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const DSText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = null;

  const DSText.displayLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.displayLarge;

  const DSText.displayMedium(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.displayMedium;

  const DSText.displaySmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.displaySmall;

  const DSText.headlineLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.headlineLarge;

  const DSText.headlineMedium(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.headlineMedium;

  const DSText.headlineSmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.headlineSmall;

  const DSText.titleLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.titleLarge;

  const DSText.titleMedium(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.titleMedium;

  const DSText.titleSmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.titleSmall;

  const DSText.bodyLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.bodyLarge;

  const DSText.bodyMedium(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.bodyMedium;

  const DSText.bodySmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.bodySmall;

  const DSText.labelLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.labelLarge;

  const DSText.labelMedium(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.labelMedium;

  const DSText.labelSmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : baseStyle = AppTheme.labelSmall;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = baseStyle != null
        ? (style != null ? baseStyle!.merge(style) : baseStyle)
        : style;

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
