import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import 'package:the_book_tool/index.dart';

class PdfService {
  Future<void> exportChaptersToPdf({
    required List<Chapter> chapters,
    required String bookName,
    required String author,
    required ReadingFont font,
    required double fontSize,
  }) async {
    // Load fonts with Unicode support (with timeout)
    final regularFont = await _loadFont(font, false).timeout(
      const Duration(seconds: 10),
      onTimeout: () async {
        // Fallback to simple font loading
        return await _loadSimpleFont(false);
      },
    );
    final boldFont = await _loadFont(font, true).timeout(
      const Duration(seconds: 10),
      onTimeout: () async {
        return await _loadSimpleFont(true);
      },
    );

    // Create PDF document
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  bookName,
                  style: pw.TextStyle(
                    fontSize: 32,
                    font: boldFont,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'by $author',
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: regularFont,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add chapters
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Chapter ${i + 1}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: regularFont,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      chapter.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        font: boldFont,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              pw.Paragraph(
                text: chapter.content,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  font: regularFont,
                  lineSpacing: 1.5,
                ),
              ),
            ];
          },
        ),
      );
    }

    // Generate PDF bytes
    final pdfBytes = await pdf.save();

    // Get save location from user
    final suggestedName = '${bookName.replaceAll(' ', '_')}.pdf';
    final path = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
        ),
      ],
    );

    if (path != null) {
      // Save the PDF
      final file = XFile.fromData(
        pdfBytes,
        name: suggestedName,
        mimeType: 'application/pdf',
      );
      await file.saveTo(path.path);
    } else {
      throw Exception('PDF export was cancelled by user');
    }
  }

  Future<pw.Font> _loadFont(ReadingFont font, bool bold) async {
    // Load Google Fonts with Unicode support for PDF
    // Using Google Fonts API to download TTF files directly
    final weight = bold ? '700' : '400';
    String fontFamily;

    switch (font) {
      case ReadingFont.lora:
        fontFamily = 'Lora';
        break;
      case ReadingFont.merriweather:
        fontFamily = 'Merriweather';
        break;
      case ReadingFont.openSans:
        fontFamily = 'Open+Sans';
        break;
      case ReadingFont.crimsonText:
        fontFamily = 'Crimson+Text';
        break;
      case ReadingFont.sourceSerif:
        fontFamily = 'Source+Serif+4';
        break;
    }

    try {
      // Download font from Google Fonts API
      final url =
          'https://fonts.googleapis.com/css2?family=$fontFamily:wght@$weight';
      final cssResponse = await http.get(Uri.parse(url));

      if (cssResponse.statusCode == 200) {
        // Parse the CSS to get the actual TTF URL
        final cssContent = cssResponse.body;
        final urlMatch = RegExp(
          r'url\((https://[^)]+\.ttf)\)',
        ).firstMatch(cssContent);

        if (urlMatch != null) {
          final ttfUrl = urlMatch.group(1)!;
          final fontResponse = await http.get(Uri.parse(ttfUrl));

          if (fontResponse.statusCode == 200) {
            return pw.Font.ttf(ByteData.view(fontResponse.bodyBytes.buffer));
          }
        }
      }
    } catch (e) {
      // Fall through to fallback
    }

    // Fallback to Roboto if loading fails
    try {
      final url =
          'https://fonts.googleapis.com/css2?family=Roboto:wght@$weight';
      final cssResponse = await http.get(Uri.parse(url));

      if (cssResponse.statusCode == 200) {
        final cssContent = cssResponse.body;
        final urlMatch = RegExp(
          r'url\((https://[^)]+\.ttf)\)',
        ).firstMatch(cssContent);

        if (urlMatch != null) {
          final ttfUrl = urlMatch.group(1)!;
          final fontResponse = await http.get(Uri.parse(ttfUrl));

          if (fontResponse.statusCode == 200) {
            return pw.Font.ttf(ByteData.view(fontResponse.bodyBytes.buffer));
          }
        }
      }
    } catch (e) {
      // Use PDF's built-in fallback
    }

    // Last resort: load a simple fallback
    return await _loadSimpleFont(bold);
  }

  Future<pw.Font> _loadSimpleFont(bool bold) async {
    // Use a hardcoded fallback - Roboto from a reliable CDN
    try {
      final url =
          'https://github.com/google/fonts/raw/main/apache/roboto/static/Roboto-${bold ? 'Bold' : 'Regular'}.ttf';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return pw.Font.ttf(ByteData.view(response.bodyBytes.buffer));
      }
    } catch (e) {
      // Continue to final fallback
    }

    // Ultimate fallback - use a very simple embedded font
    // This is Courier which has some Unicode support
    return pw.Font.courier();
  }
}
