import 'dart:typed_data';

class FileTypeService {
  /// Identifies the MIME type of a file by examining its content and extension
  static String identifyMimeType(Uint8List fileData, String filename) {
    // Try to identify by magic bytes (file signature) first
    final mimeFromContent = _identifyByMagicBytes(fileData);
    if (mimeFromContent != null) {
      return mimeFromContent;
    }

    // Fall back to extension-based identification
    final extension = _getFileExtension(filename).toLowerCase();
    return _identifyByExtension(extension);
  }

  /// Extract file extension from filename
  static String _getFileExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot > 0 && lastDot < filename.length - 1) {
      return filename.substring(lastDot + 1);
    }
    return '';
  }

  /// Identify file type by examining magic bytes (file signature)
  static String? _identifyByMagicBytes(Uint8List fileData) {
    if (fileData.isEmpty) return null;

    // Need at least a few bytes to check signatures
    if (fileData.length < 4) return null;

    // Check common image formats
    // PNG: 89 50 4E 47
    if (fileData.length >= 4 &&
        fileData[0] == 0x89 &&
        fileData[1] == 0x50 &&
        fileData[2] == 0x4E &&
        fileData[3] == 0x47) {
      return 'image/png';
    }

    // JPEG: FF D8 FF
    if (fileData.length >= 3 &&
        fileData[0] == 0xFF &&
        fileData[1] == 0xD8 &&
        fileData[2] == 0xFF) {
      return 'image/jpeg';
    }

    // GIF87a or GIF89a: 47 49 46 38 37 61 or 47 49 46 38 39 61
    if (fileData.length >= 6 &&
        fileData[0] == 0x47 &&
        fileData[1] == 0x49 &&
        fileData[2] == 0x46 &&
        fileData[3] == 0x38 &&
        (fileData[4] == 0x37 || fileData[4] == 0x39) &&
        fileData[5] == 0x61) {
      return 'image/gif';
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (fileData.length >= 12 &&
        fileData[0] == 0x52 &&
        fileData[1] == 0x49 &&
        fileData[2] == 0x46 &&
        fileData[3] == 0x46 &&
        fileData[8] == 0x57 &&
        fileData[9] == 0x45 &&
        fileData[10] == 0x42 &&
        fileData[11] == 0x50) {
      return 'image/webp';
    }

    // BMP: 42 4D
    if (fileData.length >= 2 && fileData[0] == 0x42 && fileData[1] == 0x4D) {
      return 'image/bmp';
    }

    // TIFF (Little Endian): 49 49 2A 00
    if (fileData.length >= 4 &&
        fileData[0] == 0x49 &&
        fileData[1] == 0x49 &&
        fileData[2] == 0x2A &&
        fileData[3] == 0x00) {
      return 'image/tiff';
    }

    // TIFF (Big Endian): 4D 4D 00 2A
    if (fileData.length >= 4 &&
        fileData[0] == 0x4D &&
        fileData[1] == 0x4D &&
        fileData[2] == 0x00 &&
        fileData[3] == 0x2A) {
      return 'image/tiff';
    }

    // ICO: 00 00 01 00
    if (fileData.length >= 4 &&
        fileData[0] == 0x00 &&
        fileData[1] == 0x00 &&
        fileData[2] == 0x01 &&
        fileData[3] == 0x00) {
      return 'image/x-icon';
    }

    // SVG: Check for XML header and SVG tag
    if (fileData.length >= 100) {
      final header = String.fromCharCodes(fileData.sublist(0, 100));
      if (header.contains('<?xml') && header.contains('<svg')) {
        return 'image/svg+xml';
      }
    }

    // PDF: 25 50 44 46
    if (fileData.length >= 4 &&
        fileData[0] == 0x25 &&
        fileData[1] == 0x50 &&
        fileData[2] == 0x44 &&
        fileData[3] == 0x46) {
      return 'application/pdf';
    }

    // ZIP: 50 4B 03 04 or 50 4B 05 06 or 50 4B 07 08
    if (fileData.length >= 4 &&
        fileData[0] == 0x50 &&
        fileData[1] == 0x4B &&
        (fileData[2] == 0x03 || fileData[2] == 0x05 || fileData[2] == 0x07)) {
      return 'application/zip';
    }

    return null;
  }

  /// Identify file type by file extension
  static String _identifyByExtension(String extension) {
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      case 'ico':
        return 'image/x-icon';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';
      case 'md':
        return 'text/markdown';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
      case 'flac':
        return 'audio/flac';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';

      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';

      // Default
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if the MIME type represents an image
  static bool isImage(String mimeType) {
    return mimeType.startsWith('image/');
  }

  /// Check if the MIME type represents a document
  static bool isDocument(String mimeType) {
    return mimeType.startsWith('application/') ||
        mimeType.startsWith('text/') ||
        mimeType == 'application/pdf' ||
        mimeType.contains('word') ||
        mimeType.contains('document');
  }

  /// Check if the MIME type represents audio
  static bool isAudio(String mimeType) {
    return mimeType.startsWith('audio/');
  }

  /// Check if the MIME type represents video
  static bool isVideo(String mimeType) {
    return mimeType.startsWith('video/');
  }

  /// Get a human-readable file type description
  static String getFileTypeDescription(String mimeType) {
    if (isImage(mimeType)) {
      return 'Image';
    } else if (isDocument(mimeType)) {
      return 'Document';
    } else if (isAudio(mimeType)) {
      return 'Audio';
    } else if (isVideo(mimeType)) {
      return 'Video';
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('compressed')) {
      return 'Archive';
    } else {
      return 'File';
    }
  }

  /// Get appropriate icon for file type
  static String getFileTypeIcon(String mimeType) {
    if (isImage(mimeType)) {
      return 'image';
    } else if (isDocument(mimeType)) {
      return 'description';
    } else if (isAudio(mimeType)) {
      return 'audiotrack';
    } else if (isVideo(mimeType)) {
      return 'videocam';
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return 'folder_zip';
    } else {
      return 'insert_drive_file';
    }
  }
}
