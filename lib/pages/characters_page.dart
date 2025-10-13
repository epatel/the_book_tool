import 'package:the_book_tool/index.dart';

class CharactersPage extends StatefulWidget {
  const CharactersPage({super.key});

  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
  bool _expandedAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CharacterProvider>(context, listen: false).loadCharacters();
    });
  }

  void _toggleExpandAll() {
    setState(() {
      _expandedAll = !_expandedAll;
    });
  }

  Future<void> _showAddCharacterDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => const AddCharacterDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<CharacterProvider>(context, listen: false).addCharacter(
        result['name']!,
        result['description']!,
      );
    }
  }

  Future<void> _showEditCharacterDialog(Character character) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditCharacterDialog(character: character),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<CharacterProvider>(
          context,
          listen: false,
        ).deleteCharacter(character.id!);
      } else {
        final updatedCharacter = character.copyWith(
          name: result['name'] as String,
          description: result['description'] as String,
        );
        await Provider.of<CharacterProvider>(
          context,
          listen: false,
        ).updateCharacter(updatedCharacter);
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
              title: 'Characters',
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
              child: Consumer<CharacterProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.characters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const DSSpacing.spacing16(),
                          DSText.bodyLarge(
                            'No characters yet',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const DSSpacing.spacing8(),
                          DSText.bodySmall(
                            'Tap the + button to add your first character',
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
                    itemCount: provider.characters.length,
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
                      final characters = List<Character>.from(
                        provider.characters,
                      );
                      final character = characters.removeAt(oldIndex);
                      characters.insert(newIndex, character);
                      Provider.of<CharacterProvider>(
                        context,
                        listen: false,
                      ).reorderCharacters(characters);
                    },
                    itemBuilder: (context, index) {
                      final character = provider.characters[index];
                      return Container(
                        key: ValueKey(character.id),
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacing12,
                        ),
                        child: DSCard(
                          onTap: () => _showEditCharacterDialog(character),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DSText.titleMedium(character.name),
                              const DSSpacing.spacing8(),
                              DSText.bodyMedium(
                                character.description,
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
            tooltip: 'Add Character',
            onPressed: _showAddCharacterDialog,
          ),
        ),
      ],
    );
  }
}
