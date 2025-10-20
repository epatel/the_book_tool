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
      orderIndex: 0, // Add at top
      createdAt: now,
      updatedAt: now,
    );

    try {
      // Get existing notes before inserting
      final existingNotes = List<MiscNote>.from(_notes);

      // Insert the new note
      await _repository.insert(note);

      // Reload to get the new note with its database ID
      await loadNotes();

      // Find the newly inserted note (it will be first due to orderIndex 0)
      final newNote = _notes.first;

      // Create reordered list: new note at top, then existing notes
      final reorderedNotes = [newNote, ...existingNotes];

      // Update all orderIndex values
      await _repository.reorder(reorderedNotes);

      // Final reload to get correct order
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
