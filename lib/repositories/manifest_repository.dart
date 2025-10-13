import 'package:the_book_tool/index.dart';

class ManifestRepository {
  static const String _tableName = 'manifest';

  Future<List<ManifestEntry>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      return ManifestEntry.fromMap(maps[i]);
    });
  }

  Future<ManifestEntry?> get(String key) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) {
      return null;
    }

    return ManifestEntry.fromMap(maps.first);
  }

  Future<void> set(String key, String value) async {
    final db = await DatabaseService.database;
    await db.insert(_tableName, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String key) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'key = ?', whereArgs: [key]);
  }

  Future<void> setMultiple(Map<String, String> entries) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final entry in entries.entries) {
      batch.insert(_tableName, {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<Map<String, String>> getAllAsMap() async {
    final entries = await getAll();
    return {for (var entry in entries) entry.key: entry.value};
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final entry = await get(key);
    if (entry == null) return defaultValue;
    return entry.value.toLowerCase() == 'true';
  }
}
