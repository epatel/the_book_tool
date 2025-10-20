import 'package:the_book_tool/index.dart';

class SearchService {
  List<SearchResult> searchAll({
    required String query,
    required List<Chapter> chapters,
    required List<Character> characters,
    required List<Plot> plots,
    required List<MiscNote> miscNotes,
  }) {
    // Return empty if query is too short
    if (query.length <= 2) {
      return [];
    }

    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    // Search chapters
    for (final chapter in chapters) {
      if (chapter.id == null) continue;

      // Search in title
      if (chapter.title.toLowerCase().contains(queryLower)) {
        results.add(
          SearchResult(
            type: SearchResultType.chapter,
            itemId: chapter.id!,
            itemTitle: chapter.title,
            lineAbove: '',
            matchingLine: chapter.title,
            lineBelow: chapter.content.split('\n').first,
            lineNumber: 0,
            searchQuery: query,
          ),
        );
      }

      // Search in content
      results.addAll(
        _searchInText(
          text: chapter.content,
          query: queryLower,
          type: SearchResultType.chapter,
          itemId: chapter.id!,
          itemTitle: chapter.title,
        ),
      );
    }

    // Search characters
    for (final character in characters) {
      if (character.id == null) continue;

      // Search in name
      if (character.name.toLowerCase().contains(queryLower)) {
        results.add(
          SearchResult(
            type: SearchResultType.character,
            itemId: character.id!,
            itemTitle: character.name,
            lineAbove: '',
            matchingLine: character.name,
            lineBelow: character.description.split('\n').first,
            lineNumber: 0,
            searchQuery: query,
          ),
        );
      }

      // Search in description
      results.addAll(
        _searchInText(
          text: character.description,
          query: queryLower,
          type: SearchResultType.character,
          itemId: character.id!,
          itemTitle: character.name,
        ),
      );
    }

    // Search plots
    for (final plot in plots) {
      if (plot.id == null) continue;

      // Search in title
      if (plot.title.toLowerCase().contains(queryLower)) {
        results.add(
          SearchResult(
            type: SearchResultType.plot,
            itemId: plot.id!,
            itemTitle: plot.title,
            lineAbove: '',
            matchingLine: plot.title,
            lineBelow: plot.description.split('\n').first,
            lineNumber: 0,
            searchQuery: query,
          ),
        );
      }

      // Search in description
      results.addAll(
        _searchInText(
          text: plot.description,
          query: queryLower,
          type: SearchResultType.plot,
          itemId: plot.id!,
          itemTitle: plot.title,
        ),
      );
    }

    // Search misc notes
    for (final note in miscNotes) {
      if (note.id == null) continue;

      // Search in title
      if (note.title.toLowerCase().contains(queryLower)) {
        results.add(
          SearchResult(
            type: SearchResultType.miscNote,
            itemId: note.id!,
            itemTitle: note.title,
            lineAbove: '',
            matchingLine: note.title,
            lineBelow: note.content.split('\n').first,
            lineNumber: 0,
            searchQuery: query,
          ),
        );
      }

      // Search in content
      results.addAll(
        _searchInText(
          text: note.content,
          query: queryLower,
          type: SearchResultType.miscNote,
          itemId: note.id!,
          itemTitle: note.title,
        ),
      );
    }

    return results;
  }

  List<SearchResult> _searchInText({
    required String text,
    required String query,
    required SearchResultType type,
    required int itemId,
    required String itemTitle,
  }) {
    final results = <SearchResult>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query)) {
        results.add(
          SearchResult(
            type: type,
            itemId: itemId,
            itemTitle: itemTitle,
            lineAbove: i > 0 ? lines[i - 1] : '',
            matchingLine: lines[i],
            lineBelow: i < lines.length - 1 ? lines[i + 1] : '',
            lineNumber: i,
            searchQuery: query,
          ),
        );
      }
    }

    return results;
  }
}
