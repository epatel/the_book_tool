import 'package:the_book_tool/index.dart';

class AssetRepository {
  static const String _tableName = 'assets';

  Future<List<Asset>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

  Future<Asset?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Asset.fromMap(maps.first);
  }

  Future<int> insert(Asset asset) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, asset.toMap());
  }

  Future<void> update(Asset asset) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<Asset> assets) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        asset.toMap(),
        where: 'id = ?',
        whereArgs: [asset.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
