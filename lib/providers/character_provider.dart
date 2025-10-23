import 'package:the_book_tool/index.dart';

class CharacterProvider
    extends BaseEntityProvider<Character, CharacterRepository> {
  CharacterProvider() : super(CharacterRepository());

  @override
  String get entityName => 'characters';

  @override
  bool get addAtTop => false; // Characters are added at bottom

  @override
  Character createEntity(Map<String, dynamic> params) {
    return Character(
      name: params['name'] as String,
      description: params['description'] as String,
      orderIndex: params['orderIndex'] as int,
      createdAt: params['createdAt'] as DateTime,
      updatedAt: params['updatedAt'] as DateTime,
    );
  }

  // Convenience getters and methods with specific names
  List<Character> get characters => entities;

  Future<void> loadCharacters() => load();

  Future<void> addCharacter(String name, String description) {
    return add({'name': name, 'description': description});
  }

  Future<void> updateCharacter(Character character) => update(character);

  Future<void> deleteCharacter(int id) => delete(id);

  Future<void> reorderCharacters(List<Character> characters) =>
      reorder(characters);
}
