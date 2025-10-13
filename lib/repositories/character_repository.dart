import 'package:the_book_tool/index.dart';

class CharacterRepository {
  static const String _tableName = 'characters';

  Future<List<Character>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Character.fromMap(maps[i]);
    });
  }

  Future<Character?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Character.fromMap(maps.first);
  }

  Future<int> insert(Character character) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, character.toMap());
  }

  Future<void> update(Character character) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorder(List<Character> characters) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < characters.length; i++) {
      final character = characters[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        character.toMap(),
        where: 'id = ?',
        whereArgs: [character.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
