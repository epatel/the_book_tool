import 'package:the_book_tool/index.dart';

/// Dialog for editing an existing character.
///
/// This is a thin wrapper around [EditEntityDialog] configured for characters.
class EditCharacterDialog extends StatelessWidget {
  final Character character;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;

  const EditCharacterDialog({
    super.key,
    required this.character,
    this.hasApiKey = false,
    this.searchQuery,
    this.searchLineNumber,
  });

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(
      context,
      listen: false,
    );

    return EditEntityDialog<Character>(
      config: EditEntityDialogConfig.character,
      entity: character,
      hasApiKey: hasApiKey,
      searchQuery: searchQuery,
      searchLineNumber: searchLineNumber,
      getField1Value: (character) => character.name,
      getField2Value: (character) => character.description,
      getId: (character) => character.id!,
      copyWith: (character, field1, field2) => character.copyWith(
        name: field1,
        description: field2,
      ),
      onUpdate: (context, updatedCharacter) async {
        await characterProvider.updateCharacter(updatedCharacter);
      },
      onDelete: (context, id) async {
        await characterProvider.deleteCharacter(id);
      },
    );
  }
}
