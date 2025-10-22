import 'package:the_book_tool/index.dart';

/// Service for accessing assets by alias
/// Includes caching for performance
class AssetService {
  final AssetRepository _repository = AssetRepository();

  // Cache for recently accessed assets
  static final Map<String, Asset> _cache = {};
  static const int _maxCacheSize = 50;

  /// Get an asset by its alias
  /// Returns null if no asset with the given alias exists
  Future<Asset?> getAssetByAlias(String alias) async {
    // Check cache first
    if (_cache.containsKey(alias)) {
      return _cache[alias];
    }

    // Query database
    final allAssets = await _repository.getAll();
    final asset = allAssets.cast<Asset?>().firstWhere(
      (a) => a?.alias == alias,
      orElse: () => null,
    );

    // Add to cache if found
    if (asset != null) {
      _addToCache(alias, asset);
    }

    return asset;
  }

  /// Add asset to cache with size limit
  void _addToCache(String alias, Asset asset) {
    // If cache is full, remove oldest entry
    if (_cache.length >= _maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    _cache[alias] = asset;
  }

  /// Clear the asset cache
  /// Call this when assets are modified
  static void clearCache() {
    _cache.clear();
  }

  /// Remove a specific asset from cache
  static void removeCachedAsset(String alias) {
    _cache.remove(alias);
  }
}
