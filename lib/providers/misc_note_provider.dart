import 'package:the_book_tool/index.dart';

class MiscNoteProvider
    extends BaseEntityProvider<MiscNote, MiscNoteRepository> {
  MiscNoteProvider() : super(MiscNoteRepository());

  @override
  String get entityName => 'notes';

  @override
  bool get addAtTop => true; // Notes are added at top

  @override
  MiscNote createEntity(Map<String, dynamic> params) {
    return MiscNote(
      title: params['title'] as String,
      content: params['content'] as String,
      orderIndex: params['orderIndex'] as int,
      createdAt: params['createdAt'] as DateTime,
      updatedAt: params['updatedAt'] as DateTime,
    );
  }

  // Convenience getters and methods with specific names
  List<MiscNote> get notes => entities;

  Future<void> loadNotes() => load();

  Future<void> addNote(String title, String content) {
    return add({'title': title, 'content': content});
  }

  Future<void> updateNote(MiscNote note) => update(note);

  Future<void> deleteNote(int id) => delete(id);

  Future<void> reorderNotes(List<MiscNote> notes) => reorder(notes);
}
