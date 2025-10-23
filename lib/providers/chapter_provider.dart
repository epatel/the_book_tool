import 'package:the_book_tool/index.dart';

class ChapterProvider extends BaseEntityProvider<Chapter, ChapterRepository> {
  ChapterProvider() : super(ChapterRepository());

  @override
  String get entityName => 'chapters';

  @override
  bool get addAtTop => false; // Chapters are added at bottom

  @override
  Chapter createEntity(Map<String, dynamic> params) {
    return Chapter(
      title: params['title'] as String,
      content: params['content'] as String,
      orderIndex: params['orderIndex'] as int,
      createdAt: params['createdAt'] as DateTime,
      updatedAt: params['updatedAt'] as DateTime,
    );
  }

  // Convenience getters and methods with specific names
  List<Chapter> get chapters => entities;

  Future<void> loadChapters() => load();

  Future<void> addChapter(String title, String content) {
    return add({'title': title, 'content': content});
  }

  Future<void> updateChapter(Chapter chapter) => update(chapter);

  Future<void> deleteChapter(int id) => delete(id);

  Future<void> reorderChapters(List<Chapter> chapters) => reorder(chapters);
}
