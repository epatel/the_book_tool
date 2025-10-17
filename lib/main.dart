import 'package:the_book_tool/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseService.initialize();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Restore window state
  final windowPrefs = WindowPreferencesService();
  await windowPrefs.restoreWindowState();

  // Listen for window changes to save state
  windowManager.addListener(_WindowStateListener(windowPrefs));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChapterProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => PlotProvider()),
        ChangeNotifierProvider(create: (_) => MiscNoteProvider()),
        ChangeNotifierProvider(create: (_) => PromptProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
      ],
      child: const App(),
    ),
  );
}

class _WindowStateListener extends WindowListener {
  final WindowPreferencesService _windowPrefs;

  _WindowStateListener(this._windowPrefs);

  @override
  void onWindowMoved() {
    _windowPrefs.saveWindowState();
  }

  @override
  void onWindowResized() {
    _windowPrefs.saveWindowState();
  }
}
