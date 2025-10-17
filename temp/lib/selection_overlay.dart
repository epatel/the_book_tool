import 'package:flutter/material.dart';

class TextSelectionHighlight extends StatelessWidget {
  const TextSelectionHighlight({
    super.key,
    required this.text,
    required this.selection,
    required this.style,
    required this.maxLines,
    this.padding = EdgeInsets.zero,
    this.scrollOffset = 0.0,
  });

  final String text;
  final TextSelection selection;
  final TextStyle style;
  final int maxLines;
  final EdgeInsets padding;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SelectionPainter(
        text: text,
        selection: selection,
        style: style,
        maxLines: maxLines,
        padding: padding,
        scrollOffset: scrollOffset,
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter({
    required this.text,
    required this.selection,
    required this.style,
    required this.maxLines,
    required this.padding,
    required this.scrollOffset,
  });

  final String text;
  final TextSelection selection;
  final TextStyle style;
  final int maxLines;
  final EdgeInsets padding;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );

    final maxWidth = size.width - padding.horizontal * 2 - 7;
    textPainter.layout(maxWidth: maxWidth);

    final selectionBoxes = textPainter.getBoxesForSelection(selection);

    final selectionPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final box in selectionBoxes) {
      var rect = box.toRect().shift(
        Offset(padding.left, padding.top - scrollOffset),
      );

      canvas.drawRect(rect, selectionPaint);
    }

    if (selection.isCollapsed) {
      final cursorOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: selection.baseOffset),
        Rect.zero,
      );

      final cursorPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final cursorX = cursorOffset.dx + padding.left;
      final cursorY = cursorOffset.dy + padding.top - scrollOffset;
      final cursorHeight = style.fontSize ?? 16.0;

      canvas.drawLine(
        Offset(cursorX, cursorY),
        Offset(cursorX, cursorY + cursorHeight),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.selection != selection ||
        oldDelegate.style != style ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.padding != padding ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
