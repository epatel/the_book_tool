import 'package:the_book_tool/index.dart';

class ChapterProvider extends ChangeNotifier {
  final ChapterRepository _repository = ChapterRepository();
  List<Chapter> _chapters = [];
  bool _isLoading = false;

  List<Chapter> get chapters => _chapters;
  bool get isLoading => _isLoading;

  Future<void> loadChapters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _chapters = await _repository.getAll();
    } catch (e) {
      // Handle error
      debugPrint('Error loading chapters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChapter(String title, String content) async {
    final now = DateTime.now();
    final chapter = Chapter(
      title: title,
      content: content,
      orderIndex: _chapters.length,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.insert(chapter);
      await loadChapters();
    } catch (e) {
      debugPrint('Error adding chapter: $e');
    }
  }

  Future<void> updateChapter(Chapter chapter) async {
    try {
      final updatedChapter = chapter.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedChapter);
      await loadChapters();
    } catch (e) {
      debugPrint('Error updating chapter: $e');
    }
  }

  Future<void> deleteChapter(int id) async {
    try {
      await _repository.delete(id);
      await loadChapters();
    } catch (e) {
      debugPrint('Error deleting chapter: $e');
    }
  }

  Future<void> reorderChapters(List<Chapter> chapters) async {
    try {
      await _repository.reorder(chapters);
      await loadChapters();
    } catch (e) {
      debugPrint('Error reordering chapters: $e');
    }
  }
}
