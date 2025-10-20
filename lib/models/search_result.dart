enum SearchResultType {
  chapter,
  character,
  plot,
  miscNote,
}

class SearchResult {
  final SearchResultType type;
  final int itemId;
  final String itemTitle;
  final String lineAbove;
  final String matchingLine;
  final String lineBelow;
  final int lineNumber;

  const SearchResult({
    required this.type,
    required this.itemId,
    required this.itemTitle,
    required this.lineAbove,
    required this.matchingLine,
    required this.lineBelow,
    required this.lineNumber,
  });

  String get typeLabel {
    switch (type) {
      case SearchResultType.chapter:
        return 'Chapter';
      case SearchResultType.character:
        return 'Character';
      case SearchResultType.plot:
        return 'Plot';
      case SearchResultType.miscNote:
        return 'Note';
    }
  }

  String get routePath {
    switch (type) {
      case SearchResultType.chapter:
        return '/book';
      case SearchResultType.character:
        return '/characters';
      case SearchResultType.plot:
        return '/plots';
      case SearchResultType.miscNote:
        return '/misc';
    }
  }
}
