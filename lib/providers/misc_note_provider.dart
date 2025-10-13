import 'package:the_book_tool/index.dart';

class MiscNoteProvider extends ChangeNotifier {
  final MiscNoteRepository _repository = MiscNoteRepository();
  List<MiscNote> _notes = [];
  bool _isLoading = false;

  List<MiscNote> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String title, String content) async {
    final now = DateTime.now();
    final note = MiscNote(
      title: title,
      content: content,
      orderIndex: _notes.length,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.insert(note);
      await loadNotes();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> updateNote(MiscNote note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedNote);
      await loadNotes();
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _repository.delete(id);
      await loadNotes();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  Future<void> reorderNotes(List<MiscNote> notes) async {
    try {
      await _repository.reorder(notes);
      await loadNotes();
    } catch (e) {
      debugPrint('Error reordering notes: $e');
    }
  }
}
