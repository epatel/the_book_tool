import 'package:the_book_tool/index.dart';

class CharactersPage extends StatefulWidget {
  const CharactersPage({super.key});

  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
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
      Provider.of<CharacterProvider>(context, listen: false).loadCharacters();
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

              if (_expandedAll) {
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
                        onTap: () => _showEditCharacterDialog(character),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DSText.titleMedium(
                                  _filterNotForAiMarker(character.name),
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
                              MarkdownContent(
                                data: character.description,
                                readingFont: _readingFont,
                                fontSize: _fontSize,
                              )
                            else
                              Text(
                                character.description,
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
                          Row(
                            children: [
                              DSText.titleMedium(
                                _filterNotForAiMarker(character.name),
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
                            MarkdownContent(
                              data: character.description,
                              readingFont: _readingFont,
                              fontSize: _fontSize,
                              collapsed: true,
                            )
                          else
                            DSText.bodyMedium(
                              character.description,
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
