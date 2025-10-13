import 'package:the_book_tool/index.dart';

class MiscNoteRepository {
  static const String _tableName = 'misc_notes';

  Future<List<MiscNote>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return MiscNote.fromMap(maps[i]);
    });
  }

  Future<MiscNote?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return MiscNote.fromMap(maps.first);
  }

  Future<int> insert(MiscNote note) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, note.toMap());
  }

  Future<void> update(MiscNote note) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
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

  Future<void> reorder(List<MiscNote> notes) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
