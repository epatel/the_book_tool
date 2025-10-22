import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:the_book_tool/index.dart';
import 'package:markdown/markdown.dart' as md;

class PdfService {
  /// Convert markdown text to PDF widgets
  List<pw.Widget> _markdownToPdfWidgets({
    required String markdownText,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font italicFont,
    required pw.Font boldItalicFont,
    required double fontSize,
  }) {
    // Parse markdown to AST
    final document = md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final nodes = document.parseLines(markdownText.split('\n'));

    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      widgets.addAll(
        _convertNodeToWidgets(
          node,
          regularFont: regularFont,
          boldFont: boldFont,
          italicFont: italicFont,
          boldItalicFont: boldItalicFont,
          fontSize: fontSize,
        ),
      );
    }

    return widgets;
  }

  /// Convert a markdown node to PDF widgets
  List<pw.Widget> _convertNodeToWidgets(
    md.Node node, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font italicFont,
    required pw.Font boldItalicFont,
    required double fontSize,
  }) {
    final widgets = <pw.Widget>[];

    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(
            pw.Text(
              _extractText(node),
              style: pw.TextStyle(
                font: boldFont,
                fontSize: fontSize * 2.0,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
          break;

        case 'h2':
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(
            pw.Text(
              _extractText(node),
              style: pw.TextStyle(
                font: boldFont,
                fontSize: fontSize * 1.75,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 6));
          break;

        case 'h3':
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Text(
              _extractText(node),
              style: pw.TextStyle(
                font: boldFont,
                fontSize: fontSize * 1.5,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 4));
          break;

        case 'p':
          widgets.add(
            pw.RichText(
              text: _buildTextSpan(
                node,
                regularFont: regularFont,
                boldFont: boldFont,
                italicFont: italicFont,
                boldItalicFont: boldItalicFont,
                fontSize: fontSize,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: fontSize * 0.8));
          break;

        case 'ul':
          for (final child in node.children ?? []) {
            if (child is md.Element && child.tag == 'li') {
              widgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 20,
                      child: pw.Text(
                        '•',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.RichText(
                        text: _buildTextSpan(
                          child,
                          regularFont: regularFont,
                          boldFont: boldFont,
                          italicFont: italicFont,
                          boldItalicFont: boldItalicFont,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
            }
          }
          widgets.add(pw.SizedBox(height: 4));
          break;

        case 'ol':
          int index = 1;
          for (final child in node.children ?? []) {
            if (child is md.Element && child.tag == 'li') {
              widgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 20,
                      child: pw.Text(
                        '$index.',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.RichText(
                        text: _buildTextSpan(
                          child,
                          regularFont: regularFont,
                          boldFont: boldFont,
                          italicFont: italicFont,
                          boldItalicFont: boldItalicFont,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
              index++;
            }
          }
          widgets.add(pw.SizedBox(height: 4));
          break;

        case 'blockquote':
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              padding: const pw.EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(
                    color: PdfColors.grey600,
                    width: 3,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children:
                    node.children
                        ?.expand(
                          (child) => _convertNodeToWidgets(
                            child,
                            regularFont: regularFont,
                            boldFont: boldFont,
                            italicFont: italicFont,
                            boldItalicFont: boldItalicFont,
                            fontSize: fontSize,
                          ),
                        )
                        .toList() ??
                    [],
              ),
            ),
          );
          break;

        case 'hr':
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Divider(color: PdfColors.grey400));
          widgets.add(pw.SizedBox(height: 8));
          break;

        case 'code':
          // Inline code
          widgets.add(
            pw.Text(
              _extractText(node),
              style: pw.TextStyle(
                font: regularFont,
                fontSize: fontSize * 0.9,
                color: PdfColors.grey800,
              ),
            ),
          );
          break;

        case 'pre':
          // Code block
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                _extractText(node),
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: fontSize * 0.9,
                ),
              ),
            ),
          );
          break;

        default:
          // For other elements, recursively process children
          for (final child in node.children ?? []) {
            widgets.addAll(
              _convertNodeToWidgets(
                child,
                regularFont: regularFont,
                boldFont: boldFont,
                italicFont: italicFont,
                boldItalicFont: boldItalicFont,
                fontSize: fontSize,
              ),
            );
          }
      }
    } else if (node is md.Text) {
      // Plain text node
      widgets.add(
        pw.Text(
          node.text,
          style: pw.TextStyle(font: regularFont, fontSize: fontSize),
        ),
      );
    }

    return widgets;
  }

  /// Build a text span with inline formatting (bold, italic, etc.)
  pw.TextSpan _buildTextSpan(
    md.Node node, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font italicFont,
    required pw.Font boldItalicFont,
    required double fontSize,
    bool isBold = false,
    bool isItalic = false,
  }) {
    if (node is md.Text) {
      // Select the appropriate font based on bold/italic combination
      pw.Font selectedFont;
      if (isBold && isItalic) {
        selectedFont = boldItalicFont;
      } else if (isBold) {
        selectedFont = boldFont;
      } else if (isItalic) {
        selectedFont = italicFont;
      } else {
        selectedFont = regularFont;
      }

      return pw.TextSpan(
        text: node.text,
        style: pw.TextStyle(
          font: selectedFont,
          fontSize: fontSize,
        ),
      );
    } else if (node is md.Element) {
      final children = <pw.TextSpan>[];

      for (final child in node.children ?? []) {
        final childBold = isBold || node.tag == 'strong' || node.tag == 'b';
        final childItalic = isItalic || node.tag == 'em' || node.tag == 'i';
        children.add(
          _buildTextSpan(
            child,
            regularFont: regularFont,
            boldFont: boldFont,
            italicFont: italicFont,
            boldItalicFont: boldItalicFont,
            fontSize: fontSize,
            isBold: childBold,
            isItalic: childItalic,
          ),
        );
      }

      return pw.TextSpan(children: children);
    }

    return pw.TextSpan(text: '');
  }

  /// Extract plain text from a markdown node
  String _extractText(md.Node node) {
    if (node is md.Text) {
      return node.text;
    } else if (node is md.Element) {
      return node.children?.map(_extractText).join('') ?? '';
    }
    return '';
  }

  /// Load a font with Unicode support from bundled assets
  Future<pw.Font?> _loadUnicodeFont({
    required ReadingFont readingFont,
    bool bold = false,
    bool italic = false,
  }) async {
    // Map ReadingFont enum to font file names
    // Lora and Crimson Text fall back to similar fonts
    String fontBaseName;
    switch (readingFont) {
      case ReadingFont.lora:
        // Lora not available, use Source Serif 4 as fallback (similar serif)
        fontBaseName = 'SourceSerif4';
        break;
      case ReadingFont.merriweather:
        fontBaseName = 'Merriweather';
        break;
      case ReadingFont.openSans:
        fontBaseName = 'OpenSans';
        break;
      case ReadingFont.crimsonText:
        // Crimson Text not available, use Merriweather as fallback (similar serif)
        fontBaseName = 'Merriweather';
        break;
      case ReadingFont.sourceSerif:
        fontBaseName = 'SourceSerif4';
        break;
    }

    // Determine font variant
    String fontVariant;
    if (bold && italic) {
      fontVariant = 'BoldItalic';
    } else if (bold) {
      fontVariant = 'Bold';
    } else if (italic) {
      fontVariant = 'Italic';
    } else {
      fontVariant = 'Regular';
    }

    final fontName = '$fontBaseName-$fontVariant';
    final fontPath = 'assets/fonts/$fontName.ttf';

    try {
      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      // Font loading failed, will use built-in fallback
      return null;
    }
  }

  /// Generate PDF bytes without showing save dialog
  Future<Uint8List> generatePdfBytes({
    required List<Chapter> chapters,
    required String bookName,
    required String author,
    required ReadingFont font,
    required double fontSize,
    required bool markdownEnabled,
  }) async {
    // Try to load fonts with Unicode support using the selected reading font
    final regularFont = await _loadUnicodeFont(readingFont: font);
    final boldFont = await _loadUnicodeFont(readingFont: font, bold: true);
    final italicFont = await _loadUnicodeFont(readingFont: font, italic: true);
    final boldItalicFont = await _loadUnicodeFont(
      readingFont: font,
      bold: true,
      italic: true,
    );

    // If loading failed, use built-in fonts and accept Unicode limitations
    final pdfRegularFont = regularFont ?? pw.Font.times();
    final pdfBoldFont = boldFont ?? pw.Font.timesBold();
    final pdfItalicFont = italicFont ?? pw.Font.timesItalic();
    final pdfBoldItalicFont = boldItalicFont ?? pw.Font.timesBoldItalic();

    // Create PDF document
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Position title at 1/3 of the page height
          final pageHeight = PdfPageFormat.a4.height;
          final topOffset = pageHeight / 3;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: topOffset),
              pw.Text(
                bookName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 32,
                  font: pdfBoldFont,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'by $author',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  font: pdfRegularFont,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Add chapters
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];

      // Check if first chapter is "Prologue" to adjust numbering
      final bool isPrologue =
          i == 0 && chapter.title.toLowerCase().trim() == 'prologue';
      final int chapterNumber = isPrologue
          ? 0
          : (chapters.isNotEmpty &&
                    chapters[0].title.toLowerCase().trim() == 'prologue'
                ? i
                : i + 1);

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
                    if (chapterNumber > 0)
                      pw.Text(
                        'Chapter $chapterNumber',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: pdfRegularFont,
                          color: PdfColors.grey600,
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      chapter.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        font: pdfBoldFont,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              // Render chapter content with or without markdown formatting
              if (markdownEnabled)
                ...(_markdownToPdfWidgets(
                  markdownText: chapter.content,
                  regularFont: pdfRegularFont,
                  boldFont: pdfBoldFont,
                  italicFont: pdfItalicFont,
                  boldItalicFont: pdfBoldItalicFont,
                  fontSize: fontSize,
                ))
              else
                pw.Paragraph(
                  text: chapter.content,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    font: pdfRegularFont,
                    lineSpacing: 1.5,
                  ),
                ),
            ];
          },
        ),
      );
    }

    // Generate PDF bytes
    return await pdf.save();
  }

  /// Save PDF bytes to file (shows save dialog)
  Future<void> savePdfToFile({
    required Uint8List pdfBytes,
    required String suggestedName,
  }) async {
    final fileName = '${suggestedName.replaceAll(' ', '_')}.pdf';

    final path = await getSaveLocation(
      suggestedName: fileName,
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
        name: fileName,
        mimeType: 'application/pdf',
      );
      await file.saveTo(path.path);
    } else {
      throw Exception('PDF export was cancelled by user');
    }
  }
}
