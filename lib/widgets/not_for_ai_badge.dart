import 'package:the_book_tool/index.dart';

/// A badge that indicates content is excluded from AI requests.
///
/// Displays when content contains the {not-for-ai} marker.
class NotForAiBadge extends StatelessWidget {
  const NotForAiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'This content is excluded from AI requests',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: DSText.bodySmall(
          'Not for AI',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
