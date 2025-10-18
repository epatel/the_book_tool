import 'package:the_book_tool/index.dart';

class AIResponseDialog extends StatelessWidget {
  final String response;

  const AIResponseDialog({
    super.key,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const DSText.titleLarge('AI Response'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: response,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyLarge,
              h1: Theme.of(context).textTheme.headlineMedium,
              h2: Theme.of(context).textTheme.titleLarge,
              h3: Theme.of(context).textTheme.titleMedium,
              code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      actions: [
        DSButton.primary(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
