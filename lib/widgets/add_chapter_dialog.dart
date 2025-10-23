import 'package:the_book_tool/index.dart';

/// Dialog for adding a new chapter.
///
/// This is a thin wrapper around [AddEntityDialog] configured for chapters.
class AddChapterDialog extends StatelessWidget {
  final bool hasApiKey;

  const AddChapterDialog({
    super.key,
    this.hasApiKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return AddEntityDialog(
      config: AddEntityDialogConfig.chapter,
      hasApiKey: hasApiKey,
    );
  }
}
