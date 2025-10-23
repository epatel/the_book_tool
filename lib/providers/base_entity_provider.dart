import 'package:flutter/foundation.dart';
import '../repositories/base_repository.dart';

/// Base provider for entities with common CRUD operations and state management
///
/// Type parameters:
/// - `T`: The entity type (must have id, orderIndex, createdAt, updatedAt, copyWith, toMap)
/// - `R`: The repository type (must extend `BaseRepository<T>`)
abstract class BaseEntityProvider<T, R extends BaseRepository<T>>
    extends ChangeNotifier {
  final R repository;
  List<T> _entities = [];
  bool _isLoading = false;

  BaseEntityProvider(this.repository);

  /// Get all entities
  List<T> get entities => _entities;

  /// Whether data is currently loading
  bool get isLoading => _isLoading;

  /// Entity type name for error messages (e.g., "chapter", "character")
  String get entityName;

  /// Whether new entities should be added at the top (true) or bottom (false)
  /// Defaults to false (add at bottom like chapters)
  bool get addAtTop => false;

  /// Create a new entity instance with the given parameters
  /// Subclasses must implement this to construct their specific entity type
  T createEntity(Map<String, dynamic> params);

  /// Load all entities from the database
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entities = await repository.getAll();
    } catch (e) {
      debugPrint('Error loading $entityName: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new entity
  Future<void> add(Map<String, dynamic> params) async {
    final now = DateTime.now();

    // Add standard fields
    params['createdAt'] = now;
    params['updatedAt'] = now;

    if (addAtTop) {
      // Add at top with complex reordering (for plots and notes)
      params['orderIndex'] = 0;

      try {
        // Get existing entities before inserting
        final existingEntities = List<T>.from(_entities);

        // Create and insert the new entity
        final entity = createEntity(params);
        await repository.insert(entity);

        // Reload to get the new entity with its database ID
        await load();

        // Find the newly inserted entity (it will be first due to orderIndex 0)
        final newEntity = _entities.first;

        // Create reordered list: new entity at top, then existing entities
        final reorderedEntities = [newEntity, ...existingEntities];

        // Update all orderIndex values
        await repository.reorder(reorderedEntities);

        // Final reload to get correct order
        await load();
      } catch (e) {
        debugPrint('Error adding $entityName: $e');
      }
    } else {
      // Add at bottom (for chapters)
      params['orderIndex'] = _entities.length;

      try {
        final entity = createEntity(params);
        await repository.insert(entity);
        await load();
      } catch (e) {
        debugPrint('Error adding $entityName: $e');
      }
    }
  }

  /// Update an existing entity
  Future<void> update(T entity) async {
    try {
      // Use dynamic to access copyWith method
      final updatedEntity =
          (entity as dynamic).copyWith(updatedAt: DateTime.now()) as T;
      await repository.update(updatedEntity);
      await load();
    } catch (e) {
      debugPrint('Error updating $entityName: $e');
    }
  }

  /// Delete an entity by ID
  Future<void> delete(int id) async {
    try {
      await repository.delete(id);
      await load();
    } catch (e) {
      debugPrint('Error deleting $entityName: $e');
    }
  }

  /// Reorder entities
  Future<void> reorder(List<T> entities) async {
    try {
      await repository.reorder(entities);
      await load();
    } catch (e) {
      debugPrint('Error reordering $entityName: $e');
    }
  }
}
