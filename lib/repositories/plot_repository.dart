import 'package:the_book_tool/index.dart';

class PlotRepository {
  static const String _tableName = 'plots';

  Future<List<Plot>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Plot.fromMap(maps[i]);
    });
  }

  Future<Plot?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Plot.fromMap(maps.first);
  }

  Future<int> insert(Plot plot) async {
    final db = await DatabaseService.database;
    return await db.insert(_tableName, plot.toMap());
  }

  Future<void> update(Plot plot) async {
    final db = await DatabaseService.database;
    await db.update(
      _tableName,
      plot.toMap(),
      where: 'id = ?',
      whereArgs: [plot.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<Plot> plots) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < plots.length; i++) {
      final plot = plots[i].copyWith(orderIndex: i);
      batch.update(
        _tableName,
        plot.toMap(),
        where: 'id = ?',
        whereArgs: [plot.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
