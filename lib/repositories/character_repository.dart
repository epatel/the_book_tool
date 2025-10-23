import 'package:the_book_tool/index.dart';

class CharacterRepository extends BaseRepository<Character> {
  @override
  String get tableName => 'characters';

  @override
  Character fromMap(Map<String, dynamic> map) => Character.fromMap(map);
}
