import 'package:flutter/foundation.dart';
import '../repositories/manifest_repository.dart';
import '../design_system/reading_fonts.dart';

/// Provider for reading-related UI settings that are shared across pages
class ReadingSettingsProvider extends ChangeNotifier {
  final ManifestRepository _manifestRepository = ManifestRepository();

  bool _markdownEnabled = false;
  bool _expandedAll = false;
  String _bookName = '';
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;
  bool _isLoaded = false;

  /// Whether markdown rendering is enabled
  bool get markdownEnabled => _markdownEnabled;

  /// Whether all items should be shown expanded
  bool get expandedAll => _expandedAll;

  /// The book name
  String get bookName => _bookName;

  /// The reading font
  ReadingFont get readingFont => _readingFont;

  /// The font size
  double get fontSize => _fontSize;

  /// Whether settings have been loaded
  bool get isLoaded => _isLoaded;

  /// Load all settings from the manifest
  Future<void> loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();

    _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
    _bookName = manifest['Name'] ?? '';
    _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
    _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
    _expandedAll = manifest['ExpandedAll']?.toLowerCase() == 'true';
    _isLoaded = true;

    notifyListeners();
  }

  /// Toggle the expanded/collapsed state for all items
  Future<void> toggleExpandAll() async {
    _expandedAll = !_expandedAll;
    await _manifestRepository.set('ExpandedAll', _expandedAll.toString());
    notifyListeners();
  }
}
