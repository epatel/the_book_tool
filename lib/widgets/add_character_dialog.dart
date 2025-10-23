import 'package:the_book_tool/index.dart';

/// Dialog for adding a new character.
///
/// This is a thin wrapper around [AddEntityDialog] configured for characters.
class AddCharacterDialog extends StatelessWidget {
  final bool hasApiKey;

  const AddCharacterDialog({
    super.key,
    this.hasApiKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return AddEntityDialog(
      config: AddEntityDialogConfig.character,
      hasApiKey: hasApiKey,
    );
  }
}
