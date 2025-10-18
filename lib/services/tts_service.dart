import 'package:the_book_tool/index.dart';

class TtsService {
  static const String _keyVoiceId = 'tts_voice_id';
  static const String _keyVoiceLocale = 'tts_voice_locale';
  FlutterTts? _flutterTts;
  VoidCallback? _onComplete;

  Future<FlutterTts> _getTts() async {
    if (_flutterTts != null) return _flutterTts!;

    _flutterTts = FlutterTts();

    // Set completion handler
    _flutterTts!.setCompletionHandler(() {
      _onComplete?.call();
    });

    // Initialize with saved voice if available
    final voiceId = await getVoiceId();
    final voiceLocale = await getVoiceLocale();
    if (voiceId != null && voiceLocale != null) {
      await _flutterTts!.setVoice({'name': voiceId, 'locale': voiceLocale});
    }

    return _flutterTts!;
  }

  Future<String?> getVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVoiceId);
  }

  Future<String?> getVoiceLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVoiceLocale);
  }

  Future<void> setVoiceId(String voiceId, String voiceLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVoiceId, voiceId);
    await prefs.setString(_keyVoiceLocale, voiceLocale);

    // Update current TTS instance if it exists
    final tts = await _getTts();
    await tts.setVoice({'name': voiceId, 'locale': voiceLocale});
  }

  /// Get list of enhanced/premium quality voices from the system
  Future<List<Map<String, String>>> getEnhancedVoices() async {
    final tts = await _getTts();
    final voices = await tts.getVoices;

    if (voices == null || voices.isEmpty) {
      return [];
    }

    // Filter for enhanced/premium quality voices only
    final enhancedVoices = <Map<String, String>>[];

    for (final voice in voices) {
      final quality = voice['quality'] as String?;
      final name = voice['name'] as String?;
      final locale = voice['locale'] as String?;

      // Filter for enhanced or premium quality
      if (quality != null &&
          (quality.toLowerCase().contains('enhanced') ||
              quality.toLowerCase().contains('premium')) &&
          name != null &&
          locale != null) {
        enhancedVoices.add({
          'name': name,
          'locale': locale,
          'quality': quality,
        });
      }
    }

    return enhancedVoices;
  }

  Future<void> speak(String text, {bool stripMarkdown = false}) async {
    final tts = await _getTts();

    String textToSpeak = text;
    if (stripMarkdown) {
      textToSpeak = _stripMarkdownSyntax(text);
    }

    await tts.speak(textToSpeak);
  }

  Future<void> pause() async {
    final tts = await _getTts();
    await tts.pause();
  }

  Future<void> resume() async {
    final tts = await _getTts();
    // Note: resume() may not be available on all platforms
    // If not available, we'll need to track state and use speak() again
    await tts.speak(''); // Continue from where paused
  }

  Future<void> stop() async {
    final tts = await _getTts();
    await tts.stop();
  }

  void setOnComplete(VoidCallback? callback) {
    _onComplete = callback;
  }

  /// Strip markdown syntax from text before speaking
  String _stripMarkdownSyntax(String text) {
    // Remove markdown formatting but keep the text content
    String cleaned = text;

    // Remove headers (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove bold/italic (**text** or *text* or __text__ or _text_)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Remove inline code (`text`)
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove links [text](url)
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    // Remove code blocks
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Remove horizontal rules
    cleaned = cleaned.replaceAll(RegExp(r'^---+$', multiLine: true), '');

    // Remove blockquotes (>)
    cleaned = cleaned.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    // Remove list markers (- * + 1.)
    cleaned = cleaned.replaceAll(RegExp(r'^[\*\-\+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    return cleaned.trim();
  }

  Future<void> dispose() async {
    await _flutterTts?.stop();
    _flutterTts = null;
    _onComplete = null;
  }
}
