import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:the_book_tool/index.dart';
import 'package:markdown/markdown.dart' as md;

class PdfService {
  final AssetService _assetService = AssetService();

  /// Parse image title for width and alignment specifications
  _PdfImageSpec _parseImageTitle(String? title) {
    if (title == null || title.isEmpty) {
      return _PdfImageSpec();
    }

    double? widthPercent;
    double alignment = 0.0; // -1.0 left, 0.0 center, 1.0 right

    // Parse width parameter
    final widthMatch = RegExp(r'width=([^\s]+)').firstMatch(title);
    if (widthMatch != null) {
      final widthValue = widthMatch.group(1)!;

      if (widthValue.endsWith('%')) {
        // Percentage: "50%" -> 50.0
        final percent = double.tryParse(widthValue.replaceAll('%', ''));
        if (percent != null && percent > 0 && percent <= 100) {
          widthPercent = percent;
        }
      } else if (widthValue == 'small') {
        widthPercent = 25.0;
      } else if (widthValue == 'medium') {
        widthPercent = 50.0;
      } else if (widthValue == 'large') {
        widthPercent = 75.0;
      } else {
        // Try parsing as decimal fraction: "0.5" -> 50.0
        final fraction = double.tryParse(widthValue);
        if (fraction != null && fraction > 0 && fraction <= 1) {
          widthPercent = fraction * 100;
        }
      }
    }

    // Parse align parameter
    final alignMatch = RegExp(r'align=([^\s]+)').firstMatch(title);
    if (alignMatch != null) {
      final alignValue = alignMatch.group(1)!.toLowerCase();
      switch (alignValue) {
        case 'left':
          alignment = -1.0;
          break;
        case 'right':
          alignment = 1.0;
          break;
        case 'center':
          alignment = 0.0;
          break;
      }
    }

    return _PdfImageSpec(widthPercent: widthPercent, alignment: alignment);
  }

  /// Convert markdown text to PDF widgets
  Future<List<pw.Widget>> _markdownToPdfWidgets({
    required String markdownText,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font italicFont,
    required pw.Font boldItalicFont,
    required double fontSize,
  }) async {
    // Parse markdown to AST
    final document = md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final nodes = document.parseLines(markdownText.split('\n'));

    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      widgets.addAll(
        await _convertNodeToWidgets(
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
  Future<List<pw.Widget>> _convertNodeToWidgets(
    md.Node node, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font italicFont,
    required pw.Font boldItalicFont,
    required double fontSize,
  }) async {
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
          // Check if paragraph contains images
          final hasImages = _containsImages(node);

          if (hasImages) {
            // Process paragraph with images
            for (final child in node.children ?? []) {
              if (child is md.Element && child.tag == 'img') {
                // Render image as block element
                final src = child.attributes['src'] ?? '';
                final title = child.attributes['title'];

                if (src.isNotEmpty) {
                  try {
                    final asset = await _assetService.getAssetByAlias(src);
                    if (asset != null && asset.isImage) {
                      final spec = _parseImageTitle(title);
                      final image = pw.MemoryImage(asset.fileData);
                      final availableWidth = PdfPageFormat.a4.width - 80;

                      // Calculate width if specified
                      final double? imageWidth = spec.widthPercent != null
                          ? availableWidth * (spec.widthPercent! / 100)
                          : null;

                      // Determine alignment
                      final pw.MainAxisAlignment rowAlignment;
                      if (spec.alignment == -1.0) {
                        rowAlignment = pw.MainAxisAlignment.start; // left
                      } else if (spec.alignment == 1.0) {
                        rowAlignment = pw.MainAxisAlignment.end; // right
                      } else {
                        rowAlignment = pw.MainAxisAlignment.center;
                      }

                      // Create image with alignment using TEST 6 approach
                      // TEST 6: Row + Container(width) + Image(fit: contain)
                      final pw.Widget imageChild;
                      if (imageWidth != null) {
                        // Width specified - use Container wrapper like TEST 6
                        imageChild = pw.Container(
                          width: imageWidth,
                          constraints: const pw.BoxConstraints(maxHeight: 700),
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        );
                      } else {
                        // No width specified - constrain height only
                        imageChild = pw.Container(
                          constraints: const pw.BoxConstraints(maxHeight: 700),
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        );
                      }

                      final imageWidget = pw.Row(
                        mainAxisAlignment: rowAlignment,
                        children: [imageChild],
                      );

                      widgets.add(pw.SizedBox(height: Sizes.imageTopSpacing));
                      widgets.add(imageWidget);
                      widgets.add(
                        pw.SizedBox(height: Sizes.imageBottomSpacing),
                      );
                    }
                  } catch (e) {
                    debugPrint('Failed to load asset for PDF: $src - $e');
                  }
                }
              } else {
                // Render text content
                final textSpan = _buildTextSpan(
                  child,
                  regularFont: regularFont,
                  boldFont: boldFont,
                  italicFont: italicFont,
                  boldItalicFont: boldItalicFont,
                  fontSize: fontSize,
                );
                // Only add non-empty text
                if (textSpan.text?.isNotEmpty == true ||
                    textSpan.children?.isNotEmpty == true) {
                  widgets.add(pw.RichText(text: textSpan));
                }
              }
            }
            widgets.add(pw.SizedBox(height: fontSize * 0.8));
          } else {
            // Normal paragraph without images
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
          }
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
          final blockquoteWidgets = <pw.Widget>[];
          for (final child in node.children ?? []) {
            blockquoteWidgets.addAll(
              await _convertNodeToWidgets(
                child,
                regularFont: regularFont,
                boldFont: boldFont,
                italicFont: italicFont,
                boldItalicFont: boldItalicFont,
                fontSize: fontSize,
              ),
            );
          }
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
                children: blockquoteWidgets,
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
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Text(
                _extractText(node),
                style: pw.TextStyle(
                  font: pw.Font.courier(),
                  fontSize: fontSize * 0.9,
                  color: PdfColors.grey900,
                ),
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
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              width: double.infinity,
              child: pw.Text(
                _extractText(node),
                style: pw.TextStyle(
                  font: pw.Font.courier(),
                  fontSize: fontSize * 0.85,
                  color: PdfColors.grey900,
                  lineSpacing: 1.3,
                ),
              ),
            ),
          );
          break;

        case 'img':
          // Handle images from assets (standalone, not in paragraphs)
          final src = node.attributes['src'] ?? '';
          final title = node.attributes['title'];

          if (src.isNotEmpty) {
            try {
              final asset = await _assetService.getAssetByAlias(src);
              if (asset != null && asset.isImage) {
                final spec = _parseImageTitle(title);
                final image = pw.MemoryImage(asset.fileData);
                final availableWidth = PdfPageFormat.a4.width - 80;

                // Calculate width if specified
                final double? imageWidth = spec.widthPercent != null
                    ? availableWidth * (spec.widthPercent! / 100)
                    : null;

                // Determine alignment
                final pw.MainAxisAlignment rowAlignment;
                if (spec.alignment == -1.0) {
                  rowAlignment = pw.MainAxisAlignment.start; // left
                } else if (spec.alignment == 1.0) {
                  rowAlignment = pw.MainAxisAlignment.end; // right
                } else {
                  rowAlignment = pw.MainAxisAlignment.center;
                }

                // Create image with alignment using TEST 6 approach
                // TEST 6: Row + Container(width) + Image(fit: contain)
                final pw.Widget imageChild;
                if (imageWidth != null) {
                  // Width specified - use Container wrapper like TEST 6
                  imageChild = pw.Container(
                    width: imageWidth,
                    constraints: const pw.BoxConstraints(maxHeight: 700),
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  );
                } else {
                  // No width specified - constrain height only
                  imageChild = pw.Container(
                    constraints: const pw.BoxConstraints(maxHeight: 700),
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  );
                }

                final imageWidget = pw.Row(
                  mainAxisAlignment: rowAlignment,
                  children: [imageChild],
                );

                widgets.add(pw.SizedBox(height: Sizes.imageTopSpacing));
                widgets.add(imageWidget);
                widgets.add(pw.SizedBox(height: Sizes.imageBottomSpacing));
              }
            } catch (e) {
              // Asset not found or error - skip image silently
              debugPrint('Failed to load asset for PDF: $src - $e');
            }
          }
          break;

        case 'table':
          // Handle tables
          final rows = <List<String>>[];

          // Process table rows
          for (final child in node.children ?? []) {
            if (child is md.Element &&
                (child.tag == 'thead' || child.tag == 'tbody')) {
              for (final row in child.children ?? []) {
                if (row is md.Element && row.tag == 'tr') {
                  final cells = <String>[];
                  for (final cell in row.children ?? []) {
                    if (cell is md.Element &&
                        (cell.tag == 'th' || cell.tag == 'td')) {
                      cells.add(_extractText(cell));
                    }
                  }
                  if (cells.isNotEmpty) {
                    rows.add(cells);
                  }
                }
              }
            }
          }

          if (rows.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: fontSize,
                ),
                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: fontSize,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellHeight: fontSize * 2,
                cellAlignments: {
                  for (var i = 0; i < rows.first.length; i++)
                    i: pw.Alignment.centerLeft,
                },
                data: rows,
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
          }
          break;

        default:
          // For other elements, recursively process children
          for (final child in node.children ?? []) {
            widgets.addAll(
              await _convertNodeToWidgets(
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
    bool isStrikethrough = false,
    bool isLink = false,
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

      pw.TextDecoration? decoration;
      if (isStrikethrough && isLink) {
        decoration = pw.TextDecoration.combine([
          pw.TextDecoration.lineThrough,
          pw.TextDecoration.underline,
        ]);
      } else if (isStrikethrough) {
        decoration = pw.TextDecoration.lineThrough;
      } else if (isLink) {
        decoration = pw.TextDecoration.underline;
      }

      return pw.TextSpan(
        text: node.text,
        style: pw.TextStyle(
          font: selectedFont,
          fontSize: fontSize,
          decoration: decoration,
          color: isLink ? PdfColors.blue700 : null,
        ),
      );
    } else if (node is md.Element) {
      final children = <pw.TextSpan>[];

      for (final child in node.children ?? []) {
        final childBold = isBold || node.tag == 'strong' || node.tag == 'b';
        final childItalic = isItalic || node.tag == 'em' || node.tag == 'i';
        final childStrikethrough = isStrikethrough || node.tag == 'del';
        final childLink = isLink || node.tag == 'a';
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
            isStrikethrough: childStrikethrough,
            isLink: childLink,
          ),
        );
      }

      return pw.TextSpan(children: children);
    }

    return pw.TextSpan(text: '');
  }

  /// Check if a node contains image children
  bool _containsImages(md.Node node) {
    if (node is md.Element) {
      for (final child in node.children ?? []) {
        if (child is md.Element && child.tag == 'img') {
          return true;
        }
      }
    }
    return false;
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

  /// Parse plain text with markdown image syntax and return PDF widgets
  Future<List<pw.Widget>> _parseTextWithImages({
    required String text,
    required pw.Font font,
    required double fontSize,
  }) async {
    final widgets = <pw.Widget>[];

    // Parse the text for markdown image syntax with surrounding newlines
    // Pattern captures optional leading/trailing newlines around the image tag
    final pattern = RegExp(
      r'\n*!\[([^\]]*)\]\(([^\s)]+)(?:\s+"([^"]+)")?\)\n*',
    );
    final matches = pattern.allMatches(text);

    if (matches.isEmpty) {
      // No images found, return plain text
      widgets.add(
        pw.Paragraph(
          text: text,
          style: pw.TextStyle(
            fontSize: fontSize,
            font: font,
            lineSpacing: 1.5,
          ),
        ),
      );
      return widgets;
    }

    int lastEnd = 0;
    final availableWidth = PdfPageFormat.a4.width - 80;

    for (final match in matches) {
      // Add text before the image
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          widgets.add(
            pw.Paragraph(
              text: textBefore,
              style: pw.TextStyle(
                fontSize: fontSize,
                font: font,
                lineSpacing: 1.5,
              ),
            ),
          );
        }
      }

      // Extract image components
      final alias = match.group(2)!;
      final title = match.group(3);

      // Try to load and add the image
      try {
        final asset = await _assetService.getAssetByAlias(alias);
        if (asset != null && asset.isImage) {
          final spec = _parseImageTitle(title);
          final image = pw.MemoryImage(asset.fileData);

          // Calculate width if specified
          final double? imageWidth = spec.widthPercent != null
              ? availableWidth * (spec.widthPercent! / 100)
              : null;

          // Determine alignment
          final pw.MainAxisAlignment rowAlignment;
          if (spec.alignment == -1.0) {
            rowAlignment = pw.MainAxisAlignment.start; // left
          } else if (spec.alignment == 1.0) {
            rowAlignment = pw.MainAxisAlignment.end; // right
          } else {
            rowAlignment = pw.MainAxisAlignment.center;
          }

          // Create image widget
          final pw.Widget imageChild;
          if (imageWidth != null) {
            imageChild = pw.Container(
              width: imageWidth,
              constraints: const pw.BoxConstraints(maxHeight: 700),
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          } else {
            imageChild = pw.Container(
              constraints: const pw.BoxConstraints(maxHeight: 700),
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          }

          final imageWidget = pw.Row(
            mainAxisAlignment: rowAlignment,
            children: [imageChild],
          );

          widgets.add(pw.SizedBox(height: Sizes.imageTopSpacing));
          widgets.add(imageWidget);
          widgets.add(pw.SizedBox(height: Sizes.imageBottomSpacing));
        }
      } catch (e) {
        debugPrint('Failed to load asset for PDF: $alias - $e');
      }

      lastEnd = match.end;
    }

    // Add remaining text after the last image
    if (lastEnd < text.length) {
      final textAfter = text.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        widgets.add(
          pw.Paragraph(
            text: textAfter,
            style: pw.TextStyle(
              fontSize: fontSize,
              font: font,
              lineSpacing: 1.5,
            ),
          ),
        );
      }
    }

    return widgets;
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
                author,
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

      // Pre-process markdown if enabled, or parse image tags in plain text
      List<pw.Widget> contentWidgets;
      if (markdownEnabled) {
        contentWidgets = await _markdownToPdfWidgets(
          markdownText: chapter.content,
          regularFont: pdfRegularFont,
          boldFont: pdfBoldFont,
          italicFont: pdfItalicFont,
          boldItalicFont: pdfBoldItalicFont,
          fontSize: fontSize,
        );
      } else {
        // Parse plain text for image tags
        contentWidgets = await _parseTextWithImages(
          text: chapter.content,
          font: pdfRegularFont,
          fontSize: fontSize,
        );
      }

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
              // Render chapter content
              ...contentWidgets,
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

/// Helper class to hold parsed image specifications for PDF
class _PdfImageSpec {
  final double? widthPercent; // 0.0 to 100.0 for percentage widths
  final double alignment; // -1.0 left, 0.0 center, 1.0 right

  _PdfImageSpec({
    this.widthPercent,
    this.alignment = 0.0,
  });
}
