import 'package:the_book_tool/index.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final ManifestRepository _manifestRepository = ManifestRepository();
  bool _markdownEnabled = false;
  bool _expandedAll = false;
  String _bookName = '';
  String _author = '';

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
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _bookName = manifest['Name'] ?? '';
        _author = manifest['Author'] ?? '';
      });
    }
  }

  Future<void> _showSettingsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => SettingsDialog(
        name: _bookName,
        author: _author,
        markdown: _markdownEnabled,
      ),
    );

    if (result != null && mounted) {
      await _manifestRepository.setMultiple({
        'Name': result['name'] as String,
        'Author': result['author'] as String,
        'Markdown': (result['markdown'] as bool).toString(),
      });
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
      await Provider.of<ChapterProvider>(context, listen: false).addChapter(
        result['title']!,
        result['content']!,
      );
    }
  }

  Future<void> _showEditChapterDialog(Chapter chapter) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditChapterDialog(chapter: chapter),
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
                                _expandedAll
                                    ? MarkdownBody(
                                        data: chapter.content,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 60,
                                        child: Stack(
                                          children: [
                                            SingleChildScrollView(
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              child: MarkdownBody(
                                                data: chapter.content,
                                                styleSheet: MarkdownStyleSheet(
                                                  p: TextStyle(
                                                    fontSize: 14,
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
                                DSText.bodyMedium(
                                  chapter.content,
                                  maxLines: _expandedAll ? null : 3,
                                  overflow: _expandedAll
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
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
