import 'package:the_book_tool/index.dart';

class PromptRepository {
  static const String _tableName = 'prompts';

  Future<List<Prompt>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Prompt.fromMap(maps[i]);
    });
  }

  Future<Prompt?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Prompt.fromMap(maps.first);
  }

  Future<int> insert(Prompt prompt) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, prompt.toMap());
  }

  Future<void> update(Prompt prompt) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      prompt.toMap(),
      where: 'id = ?',
      whereArgs: [prompt.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<Prompt> prompts) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < prompts.length; i++) {
      final prompt = prompts[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        prompt.toMap(),
        where: 'id = ?',
        whereArgs: [prompt.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
