import 'package:the_book_tool/index.dart';

/// A design system widget for empty states.
class DSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppTheme.iconSizeLarge,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: AppTheme.opacityDisabled),
          ),
          const DSSpacing.spacing16(),
          DSText.bodyLarge(
            title,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: AppTheme.opacityMedium),
            ),
          ),
          if (subtitle != null) ...[
            const DSSpacing.spacing8(),
            DSText.bodySmall(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: AppTheme.opacitySubtle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
