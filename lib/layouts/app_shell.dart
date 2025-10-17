import 'dart:typed_data';
import 'package:the_book_tool/index.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _updateCounter = 0;
  final ManifestRepository _manifestRepository = ManifestRepository();
  final AIService _aiService = AIService();
  final TtsService _ttsService = TtsService();
  bool _markdownEnabled = false;
  String _bookName = '';
  String _author = '';
  String _apiKey = '';
  String _contextPrompt = '';
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;
  String? _ttsVoiceId;

  @override
  void initState() {
    super.initState();
    // Listen to all providers for changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChapterProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<CharacterProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<PlotProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<MiscNoteProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);
      Provider.of<PromptProvider>(
        context,
        listen: false,
      ).addListener(_onDataChanged);

      // Load prompts so they're available for templates throughout the app
      Provider.of<PromptProvider>(
        context,
        listen: false,
      ).loadPrompts();

      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    final apiKey = await _aiService.getApiKey();
    final ttsVoiceId = await _ttsService.getVoiceId();
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _bookName = manifest['Name'] ?? '';
        _author = manifest['Author'] ?? '';
        _apiKey = apiKey ?? '';
        _contextPrompt = manifest['ContextPrompt'] ?? '';
        _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
        _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
        _ttsVoiceId = ttsVoiceId;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners
    Provider.of<ChapterProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<CharacterProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<PlotProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<MiscNoteProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    Provider.of<PromptProvider>(
      context,
      listen: false,
    ).removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _updateCounter++;
      });
    }
  }

  Future<void> _showDatabaseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const DatabaseSelectionDialog(),
    );

    if (result == true && mounted) {
      // Stop TTS if playing
      final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
      if (ttsProvider.isPlaying) {
        await ttsProvider.stop();
      }

      // Database was switched, reload all data from all providers
      if (mounted) {
        await Future.wait([
          Provider.of<ChapterProvider>(context, listen: false).loadChapters(),
          Provider.of<CharacterProvider>(context, listen: false).loadCharacters(),
          Provider.of<PlotProvider>(context, listen: false).loadPlots(),
          Provider.of<MiscNoteProvider>(context, listen: false).loadNotes(),
          Provider.of<PromptProvider>(context, listen: false).loadPrompts(),
        ]);
        // Trigger update of counts
        _onDataChanged();
        await _loadSettings();
      }
    }
  }

  Future<void> _showSettingsDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => SettingsDialog(
        name: _bookName,
        author: _author,
        markdown: _markdownEnabled,
        apiKey: _apiKey,
        contextPrompt: _contextPrompt,
        themeMode: themeProvider.themeMode,
        readingFont: _readingFont,
        fontSize: _fontSize,
        ttsVoiceId: _ttsVoiceId,
      ),
    );

    if (result != null && mounted) {
      await _manifestRepository.setMultiple({
        'Name': result['name'] as String,
        'Author': result['author'] as String,
        'Markdown': (result['markdown'] as bool).toString(),
        'ContextPrompt': result['contextPrompt'] as String,
        'ReadingFont': (result['readingFont'] as ReadingFont).name,
        'FontSize': (result['fontSize'] as double).toString(),
      });
      await _aiService.setApiKey(result['apiKey'] as String);
      await themeProvider.setThemeMode(result['themeMode'] as ThemeMode);

      // Save TTS voice if provided
      final ttsVoiceId = result['ttsVoiceId'] as String?;
      final ttsVoiceLocale = result['ttsVoiceLocale'] as String?;
      if (ttsVoiceId != null && ttsVoiceLocale != null) {
        await _ttsService.setVoiceId(ttsVoiceId, ttsVoiceLocale);
      }

      await _loadSettings();
    }
  }

  Future<void> _exportToPdf() async {
    final provider = Provider.of<ChapterProvider>(context, listen: false);

    if (provider.chapters.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No chapters to export'),
        ),
      );
      return;
    }

    // Show loading dialog and keep track of whether it's showing
    bool isDialogShowing = false;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        isDialogShowing = true;
        return PopScope(
          canPop: false,
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                DSSpacing.spacing16(),
                DSText.bodyMedium('Generating PDF...'),
              ],
            ),
          ),
        );
      },
    );

    // Generate PDF in background first
    Uint8List? pdfBytes;
    String? error;

    try {
      final pdfService = PdfService();
      pdfBytes = await pdfService.generatePdfBytes(
        chapters: provider.chapters,
        bookName: _bookName.isEmpty ? 'My Book' : _bookName,
        author: _author.isEmpty ? 'Unknown Author' : _author,
        font: _readingFont,
        fontSize: _fontSize,
        markdownEnabled: _markdownEnabled,
      );
    } catch (e) {
      error = e.toString();
    }

    // Close loading dialog now that generation is complete
    if (mounted && isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      isDialogShowing = false;
    }

    // If generation failed, show error
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Now show save dialog (without loading spinner blocking it)
    if (mounted && pdfBytes != null) {
      try {
        final pdfService = PdfService();
        await pdfService.savePdfToFile(
          pdfBytes: pdfBytes,
          suggestedName: _bookName.isEmpty ? 'My_Book' : _bookName,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show error message (user probably cancelled)
        if (mounted && !e.toString().contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PDF: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Stationary navigation panel
          Container(
            width: AppTheme.sidebarWidth,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: DSText.headlineSmall(
                          'Writing Tool',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.storage,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        tooltip: 'Library',
                        onPressed: _showDatabaseDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: ValueKey(_updateCounter),
                    padding: EdgeInsets.zero,
                    children: [
                      _NavItem(
                        key: ValueKey('chapters_$_updateCounter'),
                        icon: Icons.book,
                        title: 'Chapters',
                        path: '/book',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfChapters(),
                      ),
                      _NavItem(
                        key: ValueKey('characters_$_updateCounter'),
                        icon: Icons.people,
                        title: 'Characters',
                        path: '/characters',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfCharacters(),
                      ),
                      _NavItem(
                        key: ValueKey('plots_$_updateCounter'),
                        icon: Icons.lightbulb,
                        title: 'Plots',
                        path: '/plots',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfPlots(),
                      ),
                      _NavItem(
                        key: ValueKey('misc_$_updateCounter'),
                        icon: Icons.note,
                        title: 'Notes',
                        path: '/misc',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfMiscNotes(),
                      ),
                      _NavItem(
                        key: ValueKey('prompts_$_updateCounter'),
                        icon: Icons.psychology,
                        title: 'Prompts',
                        path: '/prompts',
                        currentPath: widget.currentPath,
                        countFuture: DatabaseService.numberOfPrompts(),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        tooltip: 'Export to PDF',
                        onPressed: _exportToPdf,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                        onPressed: _showSettingsDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;
  final String currentPath;
  final Future<int> countFuture;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.path,
    required this.currentPath,
    required this.countFuture,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == path;

    return FutureBuilder<int>(
      future: countFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return DSListTile(
          leading: icon,
          title: title,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DSText.bodySmall(
              count.toString(),
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          selected: isSelected,
          onTap: () => context.go(path),
        );
      },
    );
  }
}
