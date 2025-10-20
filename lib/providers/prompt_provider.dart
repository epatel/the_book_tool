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
      orderIndex: 0, // Add at top
      createdAt: now,
      updatedAt: now,
    );

    try {
      // Get existing prompts before inserting
      final existingPrompts = List<Prompt>.from(_prompts);

      // Insert the new prompt
      await _repository.insert(prompt);

      // Reload to get the new prompt with its database ID
      await loadPrompts();

      // Find the newly inserted prompt (it will be first due to orderIndex 0)
      final newPrompt = _prompts.first;

      // Create reordered list: new prompt at top, then existing prompts
      final reorderedPrompts = [newPrompt, ...existingPrompts];

      // Update all orderIndex values
      await _repository.reorder(reorderedPrompts);

      // Final reload to get correct order
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

  Future<void> restoreDefaults() async {
    try {
      await DatabaseService.insertDefaultPrompts();
      await loadPrompts();
    } catch (e) {
      debugPrint('Error restoring default prompts: $e');
    }
  }
}
