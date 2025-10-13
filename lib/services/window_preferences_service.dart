import 'package:the_book_tool/index.dart';

class WindowPreferencesService {
  static const String _keyWindowX = 'window_x';
  static const String _keyWindowY = 'window_y';
  static const String _keyWindowWidth = 'window_width';
  static const String _keyWindowHeight = 'window_height';

  static const double _defaultWidth = 1200.0;
  static const double _defaultHeight = 800.0;

  Future<void> saveWindowState() async {
    final prefs = await SharedPreferences.getInstance();
    final bounds = await windowManager.getBounds();

    await prefs.setDouble(_keyWindowX, bounds.left);
    await prefs.setDouble(_keyWindowY, bounds.top);
    await prefs.setDouble(_keyWindowWidth, bounds.width);
    await prefs.setDouble(_keyWindowHeight, bounds.height);
  }

  Future<void> restoreWindowState() async {
    final prefs = await SharedPreferences.getInstance();

    final x = prefs.getDouble(_keyWindowX);
    final y = prefs.getDouble(_keyWindowY);
    final width = prefs.getDouble(_keyWindowWidth) ?? _defaultWidth;
    final height = prefs.getDouble(_keyWindowHeight) ?? _defaultHeight;

    await windowManager.setSize(Size(width, height));

    if (x != null && y != null) {
      await windowManager.setPosition(Offset(x, y));
    } else {
      await windowManager.center();
    }
  }
}
