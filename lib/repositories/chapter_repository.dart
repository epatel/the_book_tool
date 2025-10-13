import 'package:the_book_tool/index.dart';

class ChapterRepository {
  static const String _tableName = 'chapters';

  Future<List<Chapter>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Chapter.fromMap(maps[i]);
    });
  }

  Future<Chapter?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Chapter.fromMap(maps.first);
  }

  Future<int> insert(Chapter chapter) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, chapter.toMap());
  }

  Future<void> update(Chapter chapter) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<Chapter> chapters) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        chapter.toMap(),
        where: 'id = ?',
        whereArgs: [chapter.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
