import 'package:the_book_tool/index.dart';

class MiscNoteRepository extends BaseRepository<MiscNote> {
  @override
  String get tableName => 'misc_notes';

  @override
  MiscNote fromMap(Map<String, dynamic> map) => MiscNote.fromMap(map);
}
