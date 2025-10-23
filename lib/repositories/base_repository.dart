import 'package:the_book_tool/index.dart';

/// Base repository providing common CRUD operations for entities with ordering
///
/// Type parameter `T` must have:
/// - `int?` id property
/// - `Map<String, dynamic> toMap()` method
/// - `T copyWith({int? orderIndex})` method for reordering
abstract class BaseRepository<T> {
  /// The database table name for this entity
  String get tableName;

  /// Convert a database map to an entity instance
  T fromMap(Map<String, dynamic> map);

  /// Get all entities ordered by order_index
  Future<List<T>> getAll() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return fromMap(maps[i]);
    });
  }

  /// Get a single entity by ID
  Future<T?> get(int id) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return fromMap(maps.first);
  }

  /// Insert a new entity and return its ID
  Future<int> insert(T entity) async {
    final db = await DatabaseService.database;
    // Use dynamic to access toMap method
    final map = (entity as dynamic).toMap() as Map<String, dynamic>;
    return await db.insert(tableName, map);
  }

  /// Update an existing entity
  Future<void> update(T entity) async {
    final db = await DatabaseService.database;
    // Use dynamic to access toMap and id
    final map = (entity as dynamic).toMap() as Map<String, dynamic>;
    final id = (entity as dynamic).id as int?;

    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an entity by ID
  Future<void> delete(int id) async {
    final db = await DatabaseService.database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Reorder a list of entities by updating their order_index
  Future<void> reorder(List<T> entities) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (var i = 0; i < entities.length; i++) {
      // Use dynamic to access copyWith, toMap, and id
      final entityWithNewIndex = (entities[i] as dynamic).copyWith(orderIndex: i) as T;
      final map = (entityWithNewIndex as dynamic).toMap() as Map<String, dynamic>;
      final id = (entityWithNewIndex as dynamic).id as int?;

      batch.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }
}
