import 'dart:typed_data';

class Asset {
  final int? id;
  final String filename;
  final String alias;
  final String mimeType;
  final Uint8List fileData;
  final int fileSize;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Uint8List? thumbnail;

  const Asset({
    this.id,
    required this.filename,
    required this.alias,
    required this.mimeType,
    required this.fileData,
    required this.fileSize,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'alias': alias,
      'mime_type': mimeType,
      'file_data': fileData,
      'file_size': fileSize,
      'order_index': orderIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'thumbnail': thumbnail,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      filename: map['filename'] as String,
      alias: map['alias'] as String,
      mimeType: map['mime_type'] as String,
      fileData: map['file_data'] as Uint8List,
      fileSize: map['file_size'] as int,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      thumbnail: map['thumbnail'] as Uint8List?,
    );
  }

  Asset copyWith({
    int? id,
    String? filename,
    String? alias,
    String? mimeType,
    Uint8List? fileData,
    int? fileSize,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? thumbnail,
  }) {
    return Asset(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      alias: alias ?? this.alias,
      mimeType: mimeType ?? this.mimeType,
      fileData: fileData ?? this.fileData,
      fileSize: fileSize ?? this.fileSize,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get hasThumbnail => thumbnail != null;
}
