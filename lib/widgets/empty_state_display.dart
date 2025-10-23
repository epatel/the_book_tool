import 'package:the_book_tool/index.dart';

/// A widget that displays an empty state with an icon, title, and subtitle.
///
/// Used across all entity list pages when there are no items to display.
class EmptyStateDisplay extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateDisplay({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const DSSpacing.spacing16(),
          DSText.bodyLarge(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const DSSpacing.spacing8(),
          DSText.bodySmall(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (action != null) ...[
            const DSSpacing.spacing24(),
            action!,
          ],
        ],
      ),
    );
  }
}
