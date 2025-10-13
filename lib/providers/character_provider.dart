import 'package:the_book_tool/index.dart';

class CharacterProvider extends ChangeNotifier {
  final CharacterRepository _repository = CharacterRepository();
  List<Character> _characters = [];
  bool _isLoading = false;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;

  Future<void> loadCharacters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _characters = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading characters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCharacter(String name, String description) async {
    final now = DateTime.now();
    final character = Character(
      name: name,
      description: description,
      orderIndex: _characters.length,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.insert(character);
      await loadCharacters();
    } catch (e) {
      debugPrint('Error adding character: $e');
    }
  }

  Future<void> updateCharacter(Character character) async {
    try {
      final updatedCharacter = character.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedCharacter);
      await loadCharacters();
    } catch (e) {
      debugPrint('Error updating character: $e');
    }
  }

  Future<void> deleteCharacter(int id) async {
    try {
      await _repository.delete(id);
      await loadCharacters();
    } catch (e) {
      debugPrint('Error deleting character: $e');
    }
  }

  Future<void> reorderCharacters(List<Character> characters) async {
    try {
      await _repository.reorder(characters);
      await loadCharacters();
    } catch (e) {
      debugPrint('Error reordering characters: $e');
    }
  }
}
