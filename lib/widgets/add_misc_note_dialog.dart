import 'package:the_book_tool/index.dart';

/// Dialog for adding a new misc note.
///
/// This is a thin wrapper around [AddEntityDialog] configured for misc notes.
class AddMiscNoteDialog extends StatelessWidget {
  final bool hasApiKey;

  const AddMiscNoteDialog({
    super.key,
    this.hasApiKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return AddEntityDialog(
      config: AddEntityDialogConfig.miscNote,
      hasApiKey: hasApiKey,
    );
  }
}
