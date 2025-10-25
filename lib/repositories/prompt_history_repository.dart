import 'package:the_book_tool/index.dart';

class PromptHistoryRepository {
  Future<int> insert(PromptHistory history) async {
    final db = await DatabaseService.database;
    return await db.insert('prompt_history', history.toMap());
  }

  Future<List<PromptHistory>> getAll() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'prompt_history',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => PromptHistory.fromMap(map)).toList();
  }

  Future<PromptHistory?> getById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'prompt_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PromptHistory.fromMap(maps.first);
  }

  Future<int> delete(int id) async {
    final db = await DatabaseService.database;
    return await db.delete(
      'prompt_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await DatabaseService.database;
    return await db.delete('prompt_history');
  }

  Future<int> getCount() async {
    final db = await DatabaseService.database;
    final count = await db
        .query('prompt_history', columns: ['COUNT(*)'])
        .then((value) => value.first['COUNT(*)']);
    return count as int;
  }
}
