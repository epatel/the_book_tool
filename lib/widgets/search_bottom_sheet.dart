import 'package:the_book_tool/index.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<SearchResult> _results = [];
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _query = query;
      if (query.length <= 2) {
        _results = [];
        return;
      }

      final chapterProvider = Provider.of<ChapterProvider>(
        context,
        listen: false,
      );
      final characterProvider = Provider.of<CharacterProvider>(
        context,
        listen: false,
      );
      final plotProvider = Provider.of<PlotProvider>(context, listen: false);
      final miscNoteProvider = Provider.of<MiscNoteProvider>(
        context,
        listen: false,
      );

      _results = _searchService.searchAll(
        query: query,
        chapters: chapterProvider.chapters,
        characters: characterProvider.characters,
        plots: plotProvider.plots,
        miscNotes: miscNoteProvider.notes,
      );
    });
  }

  Future<void> _openResult(SearchResult result) async {
    // Close the bottom sheet
    Navigator.of(context).pop();

    // Navigate to the appropriate page
    context.go(result.routePath);

    // Wait a frame for navigation to complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Open the edit dialog based on type
    switch (result.type) {
      case SearchResultType.chapter:
        final provider = Provider.of<ChapterProvider>(context, listen: false);
        final chapter = provider.chapters.firstWhere(
          (c) => c.id == result.itemId,
        );
        await _showEditChapterDialog(chapter);
        break;

      case SearchResultType.character:
        final provider = Provider.of<CharacterProvider>(
          context,
          listen: false,
        );
        final character = provider.characters.firstWhere(
          (c) => c.id == result.itemId,
        );
        await _showEditCharacterDialog(character);
        break;

      case SearchResultType.plot:
        final provider = Provider.of<PlotProvider>(context, listen: false);
        final plot = provider.plots.firstWhere((p) => p.id == result.itemId);
        await _showEditPlotDialog(plot);
        break;

      case SearchResultType.miscNote:
        final provider = Provider.of<MiscNoteProvider>(
          context,
          listen: false,
        );
        final note = provider.notes.firstWhere((n) => n.id == result.itemId);
        await _showEditMiscNoteDialog(note);
        break;
    }
  }

  Future<void> _showEditChapterDialog(Chapter chapter) async {
    final aiService = AIService();
    final apiKey = await aiService.getApiKey();

    if (!mounted) return;

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditChapterDialog(
        chapter: chapter,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );
  }

  Future<void> _showEditCharacterDialog(Character character) async {
    final aiService = AIService();
    final apiKey = await aiService.getApiKey();

    if (!mounted) return;

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditCharacterDialog(
        character: character,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );
  }

  Future<void> _showEditPlotDialog(Plot plot) async {
    final aiService = AIService();
    final apiKey = await aiService.getApiKey();

    if (!mounted) return;

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditPlotDialog(
        plot: plot,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );
  }

  Future<void> _showEditMiscNoteDialog(MiscNote note) async {
    final aiService = AIService();
    final apiKey = await aiService.getApiKey();

    if (!mounted) return;

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EditMiscNoteDialog(
        note: note,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text);
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search (min 3 characters)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _performSearch,
            ),
          ),

          // Results
          Expanded(
            child: _buildResultsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
            ),
            const DSSpacing.spacing16(),
            DSText.bodyLarge(
              'Start typing to search',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_query.length <= 2) {
      return Center(
        child: DSText.bodyLarge(
          'Type at least 3 characters',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
            ),
            const DSSpacing.spacing16(),
            DSText.bodyLarge(
              'No results found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const DSSpacing.spacing12(),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return DSCard(
      onTap: () => _openResult(result),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DSText.bodySmall(
                  result.typeLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Item title
              Expanded(
                child: DSText.titleMedium(
                  result.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const DSSpacing.spacing12(),

          // Context lines
          if (result.lineAbove.isNotEmpty) ...[
            DSText.bodySmall(
              result.lineAbove,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const DSSpacing.spacing4(),
          ],

          // Matching line with highlight
          _buildHighlightedText(result.matchingLine, _query),

          if (result.lineBelow.isNotEmpty) ...[
            const DSSpacing.spacing4(),
            DSText.bodySmall(
              result.lineBelow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
