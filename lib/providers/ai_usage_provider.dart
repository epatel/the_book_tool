import 'package:the_book_tool/index.dart';

class AIUsageProvider extends ChangeNotifier {
  int _totalTokens = 0;
  int _promptTokens = 0;
  int _completionTokens = 0;

  int get totalTokens => _totalTokens;
  int get promptTokens => _promptTokens;
  int get completionTokens => _completionTokens;

  AIUsageProvider() {
    loadUsage();
  }

  Future<void> loadUsage() async {
    final manifestRepo = ManifestRepository();
    final manifest = await manifestRepo.getAllAsMap();

    _totalTokens = int.tryParse(manifest['TotalTokens'] ?? '0') ?? 0;
    _promptTokens = int.tryParse(manifest['TotalPromptTokens'] ?? '0') ?? 0;
    _completionTokens =
        int.tryParse(manifest['TotalCompletionTokens'] ?? '0') ?? 0;

    notifyListeners();
  }

  Future<void> updateUsage(
    int promptTokens,
    int completionTokens,
    int totalTokens,
  ) async {
    _promptTokens += promptTokens;
    _completionTokens += completionTokens;
    _totalTokens += totalTokens;

    notifyListeners();
  }
}
