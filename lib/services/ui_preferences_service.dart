import 'package:the_book_tool/index.dart';

class UiPreferencesService {
  static const String _keyShowAiPrompt = 'show_ai_prompt';

  Future<bool> getShowAiPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowAiPrompt) ?? false;
  }

  Future<void> setShowAiPrompt(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAiPrompt, value);
  }
}
