import 'dart:typed_data';
import 'package:the_book_tool/index.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final ManifestRepository _manifestRepository = ManifestRepository();
  final AIService _aiService = AIService();
  bool _markdownEnabled = false;
  bool _expandedAll = false;
  String _bookName = '';
  String _author = '';
  String _apiKey = '';
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChapterProvider>(context, listen: false).loadChapters();
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    final apiKey = await _aiService.getApiKey();
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _bookName = manifest['Name'] ?? '';
        _author = manifest['Author'] ?? '';
        _apiKey = apiKey ?? '';
        _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
        _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
      });
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
        themeMode: themeProvider.themeMode,
        readingFont: _readingFont,
        fontSize: _fontSize,
      ),
    );

    if (result != null && mounted) {
      await _manifestRepository.setMultiple({
        'Name': result['name'] as String,
        'Author': result['author'] as String,
        'Markdown': (result['markdown'] as bool).toString(),
        'ReadingFont': (result['readingFont'] as ReadingFont).name,
        'FontSize': (result['fontSize'] as double).toString(),
      });
      await _aiService.setApiKey(result['apiKey'] as String);
      await themeProvider.setThemeMode(result['themeMode'] as ThemeMode);
      await _loadSettings();
    }
  }

  void _toggleExpandAll() {
    setState(() {
      _expandedAll = !_expandedAll;
    });
  }

  Future<void> _showAddChapterDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const AddChapterDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<ChapterProvider>(
        context,
        listen: false,
      ).addChapter(result['title']!, result['content']!);
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
                SizedBox(height: 16),
                Text('Generating PDF...'),
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

  Future<void> _showEditChapterDialog(Chapter chapter) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditChapterDialog(
        chapter: chapter,
        hasApiKey: _apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<ChapterProvider>(
          context,
          listen: false,
        ).deleteChapter(chapter.id!);
      } else {
        final updatedChapter = chapter.copyWith(
          title: result['title'] as String,
          content: result['content'] as String,
        );
        await Provider.of<ChapterProvider>(
          context,
          listen: false,
        ).updateChapter(updatedChapter);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            DSAppBar(
              title: _bookName,
              actions: [
                IconButton(
                  icon: Icon(
                    _expandedAll ? Icons.unfold_less : Icons.unfold_more,
                  ),
                  tooltip: _expandedAll ? 'Collapse All' : 'Expand All',
                  onPressed: _toggleExpandAll,
                ),
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
            Expanded(
              child: Consumer<ChapterProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.chapters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const DSSpacing.spacing16(),
                          DSText.bodyLarge(
                            'No chapters yet',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const DSSpacing.spacing8(),
                          DSText.bodySmall(
                            'Tap the + button to add your first chapter',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_expandedAll) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: provider.chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = provider.chapters[index];
                        return Container(
                          key: ValueKey(chapter.id),
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacing12,
                          ),
                          child: DSCard(
                            onTap: () => _showEditChapterDialog(chapter),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DSText.bodySmall(
                                      'Chapter ${index + 1}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const DSSpacing.spacing8(),
                                DSText.titleMedium(chapter.title),
                                const DSSpacing.spacing8(),
                                if (_markdownEnabled)
                                  MarkdownBody(
                                    data: chapter.content,
                                    styleSheet: MarkdownStyleSheet(
                                      p: _readingFont.getTextStyle(
                                        fontSize: _fontSize,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    chapter.content,
                                    style: _readingFont.getTextStyle(
                                      fontSize: _fontSize,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    itemCount: provider.chapters.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Material(
                            elevation: 0,
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final chapters = List<Chapter>.from(provider.chapters);
                      final chapter = chapters.removeAt(oldIndex);
                      chapters.insert(newIndex, chapter);
                      Provider.of<ChapterProvider>(
                        context,
                        listen: false,
                      ).reorderChapters(chapters);
                    },
                    itemBuilder: (context, index) {
                      final chapter = provider.chapters[index];
                      return Container(
                        key: ValueKey(chapter.id),
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacing12,
                        ),
                        child: DSCard(
                          onTap: () => _showEditChapterDialog(chapter),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DSText.bodySmall(
                                    'Chapter ${index + 1}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const DSSpacing.spacing8(),
                              DSText.titleMedium(chapter.title),
                              const DSSpacing.spacing8(),
                              if (_markdownEnabled)
                                SizedBox(
                                  height: 60,
                                  child: Stack(
                                    children: [
                                      SingleChildScrollView(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        child: MarkdownBody(
                                          data: chapter.content,
                                          styleSheet: MarkdownStyleSheet(
                                            p: _readingFont.getTextStyle(
                                              fontSize: _fontSize,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: 20,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                    .withValues(
                                                      alpha: 0.0,
                                                    ),
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  chapter.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: _readingFont.getTextStyle(
                                    fontSize: _fontSize,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: AppTheme.spacing16,
          bottom: AppTheme.spacing16,
          child: DSFloatingActionButton(
            icon: Icons.add,
            tooltip: 'Add Chapter',
            onPressed: _showAddChapterDialog,
          ),
        ),
      ],
    );
  }
}
