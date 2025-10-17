import 'package:the_book_tool/index.dart';

class PromptProvider extends ChangeNotifier {
  final PromptRepository _repository = PromptRepository();
  List<Prompt> _prompts = [];
  bool _isLoading = false;

  List<Prompt> get prompts => _prompts;
  bool get isLoading => _isLoading;

  Future<void> loadPrompts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prompts = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading prompts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPrompt(
    String title,
    String content, {
    bool command = false,
    bool isTemplate = false,
  }) async {
    final now = DateTime.now();
    final prompt = Prompt(
      title: title,
      content: content,
      command: command,
      isTemplate: isTemplate,
      orderIndex: _prompts.length,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.insert(prompt);
      await loadPrompts();
    } catch (e) {
      debugPrint('Error adding prompt: $e');
    }
  }

  Future<void> updatePrompt(Prompt prompt) async {
    try {
      final updatedPrompt = prompt.copyWith(updatedAt: DateTime.now());
      await _repository.update(updatedPrompt);
      await loadPrompts();
    } catch (e) {
      debugPrint('Error updating prompt: $e');
    }
  }

  Future<void> deletePrompt(int id) async {
    try {
      await _repository.delete(id);
      await loadPrompts();
    } catch (e) {
      debugPrint('Error deleting prompt: $e');
    }
  }

  Future<void> reorderPrompts(List<Prompt> prompts) async {
    try {
      await _repository.reorder(prompts);
      await loadPrompts();
    } catch (e) {
      debugPrint('Error reordering prompts: $e');
    }
  }
}
