import 'package:the_book_tool/index.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => BookPageState();
}

class BookPageState extends State<BookPage> {
  final AIService _aiService = AIService();
  bool _hasTtsVoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChapterProvider>(context, listen: false).loadChapters();
      _checkTtsAvailability();
    });
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
      }
    }
  }

  void _playChapter(
    Chapter chapter,
    int index,
    List<Chapter> allChapters,
    bool markdownEnabled,
  ) {
    final ttsProvider = Provider.of<TtsProvider>(context, listen: false);
    ttsProvider.playChapter(
      chapter,
      index,
      allChapters,
      markdownEnabled: markdownEnabled,
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
    return Consumer<ReadingSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            DSAppBar(
              title: settings.bookName,
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
                              ttsProvider.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause,
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
                    settings.expandedAll
                        ? Icons.unfold_less
                        : Icons.unfold_more,
                  ),
                  tooltip: settings.expandedAll ? 'Collapse All' : 'Expand All',
                  onPressed: settings.toggleExpandAll,
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
                    return const EmptyStateDisplay(
                      icon: Icons.book_outlined,
                      title: 'No chapters yet',
                      subtitle: 'Tap the + button to add your first chapter',
                    );
                  }

                  if (settings.expandedAll) {
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                DSText.bodySmall(
                                                  chapterLabel,
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                ),
                                                const DSSpacing.spacing8(),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showEditChapterDialog(
                                                        chapter,
                                                      ),
                                                  child: Row(
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
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const NotForAiBadge(),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const DSSpacing.spacing8(),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                iconSize: 20,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                        .withValues(alpha: 0.7),
                                                onPressed: () =>
                                                    _showEditChapterDialog(
                                                      chapter,
                                                    ),
                                                tooltip: 'Edit Chapter',
                                              ),
                                              if (!ttsProvider.isPlaying &&
                                                  _hasTtsVoice)
                                                IconButton(
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
                                                    settings.markdownEnabled,
                                                  ),
                                                  tooltip: 'Play',
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (settings.markdownEnabled)
                                        MarkdownContent(
                                          data: chapter.content,
                                          readingFont: settings.readingFont,
                                          fontSize: settings.fontSize,
                                        )
                                      else
                                        TextWithImages(
                                          text: chapter.content,
                                          style: settings.readingFont
                                              .getTextStyle(
                                                fontSize: settings.fontSize,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (chapterLabel.isNotEmpty)
                                          DSText.bodySmall(
                                            chapterLabel,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        if (chapterLabel.isNotEmpty)
                                          const DSSpacing.spacing8(),
                                        GestureDetector(
                                          onTap: () =>
                                              _showEditChapterDialog(chapter),
                                          child: Row(
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
                                                const NotForAiBadge(),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const DSSpacing.spacing8(),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    iconSize: 20,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                    onPressed: () =>
                                        _showEditChapterDialog(chapter),
                                    tooltip: 'Edit Chapter',
                                  ),
                                ],
                              ),
                              const DSSpacing.spacing8(),
                              if (settings.markdownEnabled)
                                MarkdownContent(
                                  data: chapter.content,
                                  readingFont: settings.readingFont,
                                  fontSize: settings.fontSize,
                                  collapsed: true,
                                  showGradientOverlay: true,
                                )
                              else
                                DSText.bodyMedium(
                                  chapter.content,
                                  maxLines: AppTheme.maxLinesPreview,
                                  overflow: TextOverflow.ellipsis,
                                  style: settings.readingFont.getTextStyle(
                                    fontSize: settings.fontSize,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
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
      },
    );
  }
}
