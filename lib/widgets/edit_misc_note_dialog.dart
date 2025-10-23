import 'package:the_book_tool/index.dart';

/// Dialog for editing an existing misc note.
///
/// This is a thin wrapper around [EditEntityDialog] configured for misc notes.
class EditMiscNoteDialog extends StatelessWidget {
  final MiscNote note;
  final bool hasApiKey;
  final String? searchQuery;
  final int? searchLineNumber;

  const EditMiscNoteDialog({
    super.key,
    required this.note,
    this.hasApiKey = false,
    this.searchQuery,
    this.searchLineNumber,
  });

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<MiscNoteProvider>(
      context,
      listen: false,
    );

    return EditEntityDialog<MiscNote>(
      config: EditEntityDialogConfig.miscNote,
      entity: note,
      hasApiKey: hasApiKey,
      searchQuery: searchQuery,
      searchLineNumber: searchLineNumber,
      getField1Value: (note) => note.title,
      getField2Value: (note) => note.content,
      getId: (note) => note.id!,
      copyWith: (note, field1, field2) => note.copyWith(
        title: field1,
        content: field2,
      ),
      onUpdate: (context, updatedNote) async {
        await noteProvider.updateNote(updatedNote);
      },
      onDelete: (context, id) async {
        await noteProvider.deleteNote(id);
      },
    );
  }
}
