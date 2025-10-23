import 'package:the_book_tool/index.dart';

class ChapterRepository extends BaseRepository<Chapter> {
  @override
  String get tableName => 'chapters';

  @override
  Chapter fromMap(Map<String, dynamic> map) => Chapter.fromMap(map);
}
