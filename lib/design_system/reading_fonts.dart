import 'package:the_book_tool/index.dart';

/// Available reading fonts for chapter content
enum ReadingFont {
  lora('Lora', 'Elegant serif font'),
  merriweather('Merriweather', 'Designed for screens'),
  openSans('Open Sans', 'Clean sans-serif'),
  crimsonText('Crimson Text', 'Book-like serif'),
  sourceSerif('Source Serif 4', 'Adobe reading font');

  final String displayName;
  final String description;

  const ReadingFont(this.displayName, this.description);

  /// Get the TextStyle for this font
  TextStyle getTextStyle({double fontSize = 14, Color? color}) {
    switch (this) {
      case ReadingFont.lora:
        return GoogleFonts.lora(fontSize: fontSize, color: color);
      case ReadingFont.merriweather:
        return GoogleFonts.merriweather(fontSize: fontSize, color: color);
      case ReadingFont.openSans:
        return GoogleFonts.openSans(fontSize: fontSize, color: color);
      case ReadingFont.crimsonText:
        return GoogleFonts.crimsonText(fontSize: fontSize, color: color);
      case ReadingFont.sourceSerif:
        return GoogleFonts.sourceSerif4(fontSize: fontSize, color: color);
    }
  }

  /// Parse font from string
  static ReadingFont fromString(String? value) {
    if (value == null) return ReadingFont.lora;
    try {
      return ReadingFont.values.firstWhere(
        (font) => font.name == value,
        orElse: () => ReadingFont.lora,
      );
    } catch (e) {
      return ReadingFont.lora;
    }
  }
}
