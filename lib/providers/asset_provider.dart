import 'dart:typed_data';
import 'package:the_book_tool/index.dart';

class AssetProvider extends ChangeNotifier {
  final AssetRepository _repository = AssetRepository();
  List<Asset> _assets = [];
  bool _isLoading = false;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  Future<void> loadAssets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _assets = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading assets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAsset(
    String filename,
    String alias,
    String mimeType,
    Uint8List fileData, {
    Uint8List? thumbnail,
  }) async {
    final now = DateTime.now();
    final asset = Asset(
      filename: filename,
      alias: alias,
      mimeType: mimeType,
      fileData: fileData,
      fileSize: fileData.length,
      orderIndex: 0,
      createdAt: now,
      updatedAt: now,
      thumbnail: thumbnail,
    );

    try {
      final existingAssets = List<Asset>.from(_assets);
      await _repository.insert(asset);
      await loadAssets();

      if (_assets.isNotEmpty) {
        final newAsset = _assets.first;
        final reorderedAssets = [newAsset, ...existingAssets];
        await _repository.reorder(reorderedAssets);
        await loadAssets();
      }
    } catch (e) {
      debugPrint('Error adding asset: $e');
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      final updatedAsset = asset.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedAsset);
      await loadAssets();
    } catch (e) {
      debugPrint('Error updating asset: $e');
    }
  }

  Future<void> deleteAsset(int id) async {
    try {
      await _repository.delete(id);
      await loadAssets();
    } catch (e) {
      debugPrint('Error deleting asset: $e');
    }
  }

  Future<void> reorderAssets(List<Asset> assets) async {
    try {
      await _repository.reorder(assets);
      await loadAssets();
    } catch (e) {
      debugPrint('Error reordering assets: $e');
    }
  }
}
