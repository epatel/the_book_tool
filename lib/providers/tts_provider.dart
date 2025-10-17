import 'package:the_book_tool/index.dart';

class TtsProvider extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  bool _isPlaying = false;
  bool _isPaused = false;
  int? _currentChapterIndex;
  List<Chapter> _chapters = [];
  bool _markdownEnabled = false;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int? get currentChapterIndex => _currentChapterIndex;

  TtsProvider() {
    _ttsService.setOnComplete(_onSpeechComplete);
  }

  Future<bool> hasVoiceConfigured() async {
    final voiceId = await _ttsService.getVoiceId();
    final voiceLocale = await _ttsService.getVoiceLocale();
    return voiceId != null && voiceLocale != null;
  }

  Future<void> playChapter(
    Chapter chapter,
    int chapterIndex,
    List<Chapter> allChapters, {
    bool markdownEnabled = false,
  }) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;
    _isPaused = false;
    _currentChapterIndex = chapterIndex;
    _chapters = allChapters;
    _markdownEnabled = markdownEnabled;
    notifyListeners();

    try {
      await _ttsService.speak(
        chapter.content,
        stripMarkdown: markdownEnabled,
      );
    } catch (e) {
      debugPrint('Error playing chapter: $e');
      await stop();
    }
  }

  Future<void> playAllChapters(
    List<Chapter> chapters, {
    bool markdownEnabled = false,
    int startIndex = 0,
  }) async {
    if (chapters.isEmpty) return;

    _chapters = chapters;
    _markdownEnabled = markdownEnabled;

    await playChapter(
      chapters[startIndex],
      startIndex,
      chapters,
      markdownEnabled: markdownEnabled,
    );
  }

  Future<void> pause() async {
    if (!_isPlaying || _isPaused) return;

    try {
      await _ttsService.pause();
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    if (!_isPlaying || !_isPaused) return;

    try {
      await _ttsService.resume();
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }

  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      await _ttsService.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentChapterIndex = null;
      _chapters = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  void _onSpeechComplete() {
    if (!_isPlaying) return;

    // Check if there's a next chapter to play
    if (_currentChapterIndex != null &&
        _currentChapterIndex! < _chapters.length - 1) {
      final nextIndex = _currentChapterIndex! + 1;
      playChapter(
        _chapters[nextIndex],
        nextIndex,
        _chapters,
        markdownEnabled: _markdownEnabled,
      );
    } else {
      // No more chapters, stop playback
      stop();
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
