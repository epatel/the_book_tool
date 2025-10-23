import 'package:the_book_tool/index.dart';

class CharactersPage extends StatefulWidget {
  const CharactersPage({super.key});

  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CharacterProvider>(context, listen: false).loadCharacters();
    });
  }

  Future<void> _showAddCharacterDialog() async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AddCharacterDialog(
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      await Provider.of<CharacterProvider>(
        context,
        listen: false,
      ).addCharacter(result['name']!, result['description']!);
    }
  }

  Future<void> _showEditCharacterDialog(Character character) async {
    // Check API key freshly before showing dialog
    final apiKey = await _aiService.getApiKey();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditCharacterDialog(
        character: character,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );

    if (result != null && mounted) {
      if (result['delete'] == true) {
        await Provider.of<CharacterProvider>(
          context,
          listen: false,
        ).deleteCharacter(character.id!);
      }
    }
  }

  bool _shouldShowNotForAiBadge(String name, String description) {
    return name.contains('{not-for-ai}') ||
        description.contains('{not-for-ai}');
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
              title: 'Characters',
              titleActions: [
                IconButton(
                  icon: const DSAddIcon(),
                  tooltip: 'Add Character',
                  onPressed: _showAddCharacterDialog,
                ),
              ],
              actions: [
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

                  if (settings.expandedAll) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: provider.characters.length,
                      itemBuilder: (context, index) {
                        final character = provider.characters[index];
                        return Container(
                          key: ValueKey(character.id),
                          width: double.infinity,
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
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showEditCharacterDialog(character),
                                        child: Row(
                                          children: [
                                            DSText.titleMedium(
                                              _filterNotForAiMarker(
                                                character.name,
                                              ),
                                            ),
                                            if (_shouldShowNotForAiBadge(
                                              character.name,
                                              character.description,
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
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
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
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              )
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
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
                                          _showEditCharacterDialog(character),
                                      tooltip: 'Edit Character',
                                    ),
                                  ],
                                ),
                                const DSSpacing.spacing8(),
                                if (settings.markdownEnabled)
                                  MarkdownContent(
                                    data: character.description,
                                    readingFont: settings.readingFont,
                                    fontSize: settings.fontSize,
                                  )
                                else
                                  Text(
                                    character.description,
                                    style: settings.readingFont.getTextStyle(
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
                        );
                      },
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          _showEditCharacterDialog(character),
                                      child: Row(
                                        children: [
                                          DSText.titleMedium(
                                            _filterNotForAiMarker(
                                              character.name,
                                            ),
                                          ),
                                          if (_shouldShowNotForAiBadge(
                                            character.name,
                                            character.description,
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
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          )
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
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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
                                        _showEditCharacterDialog(character),
                                    tooltip: 'Edit Character',
                                  ),
                                ],
                              ),
                              const DSSpacing.spacing8(),
                              if (settings.markdownEnabled)
                                MarkdownContent(
                                  data: character.description,
                                  readingFont: settings.readingFont,
                                  fontSize: settings.fontSize,
                                  collapsed: true,
                                )
                              else
                                DSText.bodyMedium(
                                  character.description,
                                  maxLines: 3,
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
