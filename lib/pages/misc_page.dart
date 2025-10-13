import 'package:the_book_tool/index.dart';

class MiscPage extends StatefulWidget {
  const MiscPage({super.key});

  @override
  State<MiscPage> createState() => _MiscPageState();
}

class _MiscPageState extends State<MiscPage> {
  bool _expandedAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MiscNoteProvider>(context, listen: false).loadNotes();
    });
  }

  void _toggleExpandAll() {
    setState(() {
      _expandedAll = !_expandedAll;
    });
  }

  Future<void> _showAddNoteDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const AddMiscNoteDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<MiscNoteProvider>(context, listen: false).addNote(
        result['title']!,
        result['content']!,
      );
    }
  }

  Future<void> _showEditNoteDialog(MiscNote note) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditMiscNoteDialog(note: note),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            DSAppBar(
              title: 'Misc',
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
                              DSText.titleMedium(note.title),
                              const DSSpacing.spacing8(),
                              DSText.bodyMedium(
                                note.content,
                                maxLines: _expandedAll ? null : 3,
                                overflow: _expandedAll
                                    ? null
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
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
            tooltip: 'Add Note',
            onPressed: _showAddNoteDialog,
          ),
        ),
      ],
    );
  }
}
