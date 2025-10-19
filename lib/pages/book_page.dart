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
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;
  bool _hasTtsVoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChapterProvider>(context, listen: false).loadChapters();
      _loadSettings();
      _checkTtsAvailability();
    });
  }

  Future<void> _loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _bookName = manifest['Name'] ?? '';
        _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
        _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
        _expandedAll = manifest['ExpandedAll']?.toLowerCase() == 'true';
      });
    }
  }

  Future<void> _checkTtsAvailability() async {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    final hasVoice = await ttsProvider.hasVoiceConfigured();
    if (mounted) {
      setState(() {
        _hasTtsVoice = hasVoice;
      });
    }
  }

  Future<void> _toggleExpandAll() async {
    setState(() {
      _expandedAll = !_expandedAll;
    });
    await _manifestRepository.set('ExpandedAll', _expandedAll.toString());
  }

  Future<void> _showAddChapterDialog() async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AddChapterDialog(
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      await Provider.of<ChapterProvider>(
        context,
        listen: false,
      ).addChapter(result['title']!, result['content']!);
    }
  }

  Future<void> _showEditChapterDialog(Chapter chapter) async {
    // Stop TTS if playing
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    if (ttsProvider.isPlaying) {
      await ttsProvider.stop();
    }

    if (!mounted) return;

    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditChapterDialog(
        chapter: chapter,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
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

  void _playChapter(Chapter chapter, int index, List<Chapter> allChapters) {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    ttsProvider.playChapter(
      chapter,
      index,
      allChapters,
      markdownEnabled: _markdownEnabled,
    );
  }

  String _getChapterLabel(List<Chapter> chapters, int index) {
    // Check if first chapter is "Prologue"
    final bool isPrologue =
        index == 0 && chapters[index].title.toLowerCase().trim() == 'prologue';

    if (isPrologue) {
      return ''; // No label for prologue
    }

    // If first chapter is prologue, adjust numbering for subsequent chapters
    final int chapterNumber =
        chapters.isNotEmpty &&
            chapters[0].title.toLowerCase().trim() == 'prologue'
        ? index
        : index + 1;

    return 'Chapter $chapterNumber';
  }

  bool _shouldShowNotForAiBadge(String title, String content) {
    return title.contains('{not-for-ai}') || content.contains('{not-for-ai}');
  }

  String _filterNotForAiMarker(String text) {
    return text.replaceAll('{not-for-ai}', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DSAppBar(
          title: _bookName,
          titleActions: [
            IconButton(
              icon: const DSAddIcon(),
              tooltip: 'Add Chapter',
              onPressed: _showAddChapterDialog,
            ),
          ],
          actions: [
            Consumer<TtsProvider>(
              builder: (context, ttsProvider, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ttsProvider.isPlaying)
                      IconButton(
                        icon: Icon(
                          ttsProvider.isPaused ? Icons.play_arrow : Icons.pause,
                        ),
                        tooltip: ttsProvider.isPaused ? 'Resume' : 'Pause',
                        onPressed: ttsProvider.isPaused
                            ? ttsProvider.resume
                            : ttsProvider.pause,
                      ),
                    if (ttsProvider.isPlaying)
                      IconButton(
                        icon: const Icon(Icons.stop),
                        tooltip: 'Stop',
                        onPressed: ttsProvider.stop,
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(
                _expandedAll ? Icons.unfold_less : Icons.unfold_more,
              ),
              tooltip: _expandedAll ? 'Collapse All' : 'Expand All',
              onPressed: _toggleExpandAll,
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
                        size: AppTheme.iconSizeLarge,
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
                    final chapterLabel = _getChapterLabel(
                      provider.chapters,
                      index,
                    );
                    return Consumer<TtsProvider>(
                      builder: (context, ttsProvider, child) {
                        final isPlaying =
                            ttsProvider.isPlaying &&
                            ttsProvider.currentChapterIndex == index;
                        return Container(
                          key: ValueKey(chapter.id),
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacing12,
                          ),
                          child: Container(
                            decoration: isPlaying
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  )
                                : null,
                            child: DSCard(
                              onTap: () => _showEditChapterDialog(chapter),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (chapterLabel.isNotEmpty)
                                        Row(
                                          children: [
                                            DSText.bodySmall(
                                              chapterLabel,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (chapterLabel.isNotEmpty)
                                        const DSSpacing.spacing8(),
                                      Row(
                                        children: [
                                          DSText.titleMedium(
                                            _filterNotForAiMarker(
                                              chapter.title,
                                            ),
                                          ),
                                          if (_shouldShowNotForAiBadge(
                                            chapter.title,
                                            chapter.content,
                                          )) ...[
                                            const SizedBox(width: 8),
                                            Tooltip(
                                              message:
                                                  'This content is excluded from AI requests',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: DSText.bodySmall(
                                                  'Not for AI',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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
                                  if (!ttsProvider.isPlaying && _hasTtsVoice)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.play_circle_filled,
                                        ),
                                        iconSize: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        onPressed: () => _playChapter(
                                          chapter,
                                          index,
                                          provider.chapters,
                                        ),
                                        tooltip: 'Play',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                  final chapterLabel = _getChapterLabel(
                    provider.chapters,
                    index,
                  );
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
                          if (chapterLabel.isNotEmpty)
                            Row(
                              children: [
                                DSText.bodySmall(
                                  chapterLabel,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          if (chapterLabel.isNotEmpty)
                            const DSSpacing.spacing8(),
                          Row(
                            children: [
                              DSText.titleMedium(
                                _filterNotForAiMarker(chapter.title),
                              ),
                              if (_shouldShowNotForAiBadge(
                                chapter.title,
                                chapter.content,
                              )) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'This content is excluded from AI requests',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        999,
                                      ),
                                    ),
                                    child: DSText.bodySmall(
                                      'Not for AI',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const DSSpacing.spacing8(),
                          if (_markdownEnabled)
                            SizedBox(
                              height: AppTheme.collapsedContentHeight,
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
                                    height: AppTheme.gradientOverlayHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface.withValues(
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
                              maxLines: AppTheme.maxLinesPreview,
                              overflow: TextOverflow.ellipsis,
                              style: _readingFont.getTextStyle(
                                fontSize: _fontSize,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
    );
  }
}
