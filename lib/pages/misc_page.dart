import 'package:the_book_tool/index.dart';

class MiscPage extends StatefulWidget {
  const MiscPage({super.key});

  @override
  State<MiscPage> createState() => _MiscPageState();
}

class _MiscPageState extends State<MiscPage> {
  final ManifestRepository _manifestRepository = ManifestRepository();
  final AIService _aiService = AIService();
  bool _expandedAll = false;
  bool _markdownEnabled = false;
  ReadingFont _readingFont = ReadingFont.lora;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MiscNoteProvider>(context, listen: false).loadNotes();
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final manifest = await _manifestRepository.getAllAsMap();
    if (mounted) {
      setState(() {
        _markdownEnabled = manifest['Markdown']?.toLowerCase() == 'true';
        _readingFont = ReadingFont.fromString(manifest['ReadingFont']);
        _fontSize = double.tryParse(manifest['FontSize'] ?? '14.0') ?? 14.0;
        _expandedAll = manifest['ExpandedAll']?.toLowerCase() == 'true';
      });
    }
  }

  Future<void> _toggleExpandAll() async {
    setState(() {
      _expandedAll = !_expandedAll;
    });
    await _manifestRepository.set('ExpandedAll', _expandedAll.toString());
  }

  Future<void> _showAddNoteDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const AddMiscNoteDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<MiscNoteProvider>(
        context,
        listen: false,
      ).addNote(result['title']!, result['content']!);
    }
  }

  Future<void> _showEditNoteDialog(MiscNote note) async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditMiscNoteDialog(
        note: note,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<MiscNoteProvider>(
          context,
          listen: false,
        ).deleteNote(note.id!);
      } else {
        final updatedNote = note.copyWith(
          title: result['title'] as String,
          content: result['content'] as String,
        );
        await Provider.of<MiscNoteProvider>(
          context,
          listen: false,
        ).updateNote(updatedNote);
      }
    }
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
          title: 'Notes',
          titleActions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Note',
              onPressed: _showAddNoteDialog,
            ),
          ],
          actions: [
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
          child: Consumer<MiscNoteProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const DSSpacing.spacing16(),
                      DSText.bodyLarge(
                        'No notes yet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const DSSpacing.spacing8(),
                      DSText.bodySmall(
                        'Tap the + button to add your first note',
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
                  itemCount: provider.notes.length,
                  itemBuilder: (context, index) {
                    final note = provider.notes[index];
                    return Container(
                      key: ValueKey(note.id),
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing12,
                      ),
                      child: DSCard(
                        onTap: () => _showEditNoteDialog(note),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DSText.titleMedium(
                                  _filterNotForAiMarker(note.title),
                                ),
                                if (_shouldShowNotForAiBadge(
                                  note.title,
                                  note.content,
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
                              MarkdownBody(
                                data: note.content,
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
                                note.content,
                                style: _readingFont.getTextStyle(
                                  fontSize: _fontSize,
                                  color: Theme.of(context).colorScheme.onSurface
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
                itemCount: provider.notes.length,
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
                  final notes = List<MiscNote>.from(provider.notes);
                  final note = notes.removeAt(oldIndex);
                  notes.insert(newIndex, note);
                  Provider.of<MiscNoteProvider>(
                    context,
                    listen: false,
                  ).reorderNotes(notes);
                },
                itemBuilder: (context, index) {
                  final note = provider.notes[index];
                  return Container(
                    key: ValueKey(note.id),
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.spacing12,
                    ),
                    child: DSCard(
                      onTap: () => _showEditNoteDialog(note),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DSText.titleMedium(
                                _filterNotForAiMarker(note.title),
                              ),
                              if (_shouldShowNotForAiBadge(
                                note.title,
                                note.content,
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
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: MarkdownBody(
                                  data: note.content,
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
                            )
                          else
                            DSText.bodyMedium(
                              note.content,
                              maxLines: 3,
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
