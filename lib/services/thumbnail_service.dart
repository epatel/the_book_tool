import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class ThumbnailService {
  static const int _thumbnailMaxDimension = 200;

  /// Generates a thumbnail from image data
  /// Returns null if thumbnail generation fails
  static Future<Uint8List?> generateThumbnail(Uint8List imageData) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Calculate thumbnail dimensions maintaining aspect ratio
      final int width = image.width;
      final int height = image.height;

      double scale;
      if (width > height) {
        scale = _thumbnailMaxDimension / width;
      } else {
        scale = _thumbnailMaxDimension / height;
      }

      final int thumbnailWidth = (width * scale).round();
      final int thumbnailHeight = (height * scale).round();

      // Create a picture recorder to draw the scaled image
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Draw the scaled image
      final srcRect = ui.Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        height.toDouble(),
      );
      final dstRect = ui.Rect.fromLTWH(
        0,
        0,
        thumbnailWidth.toDouble(),
        thumbnailHeight.toDouble(),
      );

      canvas.drawImageRect(image, srcRect, dstRect, ui.Paint());

      // Convert to image
      final picture = recorder.endRecording();
      final thumbnailImage = await picture.toImage(
        thumbnailWidth,
        thumbnailHeight,
      );

      // Convert to byte data (PNG format)
      final byteData = await thumbnailImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('Failed to convert thumbnail to byte data');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
}
