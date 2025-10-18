import 'dart:convert';
import 'package:the_book_tool/index.dart';

class BookDataService {
  final ManifestRepository _manifestRepository = ManifestRepository();
  final ChapterRepository _chapterRepository = ChapterRepository();
  final CharacterRepository _characterRepository = CharacterRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final MiscNoteRepository _miscNoteRepository = MiscNoteRepository();

  /// Check if content contains the not-for-ai marker
  bool _shouldFilterFromAI(String text) {
    return text.contains('{not-for-ai}');
  }

  Future<Map<String, dynamic>> collectAllBookData() async {
    final manifest = await _manifestRepository.getAllAsMap();
    final chapters = await _chapterRepository.getAll();
    final characters = await _characterRepository.getAll();
    final plots = await _plotRepository.getAll();
    final miscNotes = await _miscNoteRepository.getAll();

    return {
      'manifest': {
        'name': manifest['Name'] ?? '',
        'author': manifest['Author'] ?? '',
        'version': manifest['Version'] ?? '',
        'markdown': manifest['Markdown']?.toLowerCase() == 'true',
      },
      'chapters': chapters
          .where(
            (chapter) =>
                !_shouldFilterFromAI(chapter.title) &&
                !_shouldFilterFromAI(chapter.content),
          )
          .map(
            (chapter) => {
              'id': chapter.id,
              'title': chapter.title,
              'content': chapter.content,
              'orderIndex': chapter.orderIndex,
              'createdAt': chapter.createdAt.toIso8601String(),
              'updatedAt': chapter.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'characters': characters
          .where(
            (character) =>
                !_shouldFilterFromAI(character.name) &&
                !_shouldFilterFromAI(character.description),
          )
          .map(
            (character) => {
              'id': character.id,
              'name': character.name,
              'description': character.description,
              'orderIndex': character.orderIndex,
              'createdAt': character.createdAt.toIso8601String(),
              'updatedAt': character.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'plots': plots
          .where(
            (plot) =>
                !_shouldFilterFromAI(plot.title) &&
                !_shouldFilterFromAI(plot.description),
          )
          .map(
            (plot) => {
              'id': plot.id,
              'title': plot.title,
              'description': plot.description,
              'orderIndex': plot.orderIndex,
              'createdAt': plot.createdAt.toIso8601String(),
              'updatedAt': plot.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'miscNotes': miscNotes
          .where(
            (note) =>
                !_shouldFilterFromAI(note.title) &&
                !_shouldFilterFromAI(note.content),
          )
          .map(
            (note) => {
              'id': note.id,
              'title': note.title,
              'content': note.content,
              'orderIndex': note.orderIndex,
              'createdAt': note.createdAt.toIso8601String(),
              'updatedAt': note.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  String toJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  Future<String> collectAllBookDataAsJson() async {
    final data = await collectAllBookData();
    return toJson(data);
  }
}
