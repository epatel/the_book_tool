class MiscNote {
  final int? id;
  final String title;
  final String content;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MiscNote({
    this.id,
    required this.title,
    required this.content,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order_index': orderIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MiscNote.fromMap(Map<String, dynamic> map) {
    return MiscNote(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  MiscNote copyWith({
    int? id,
    String? title,
    String? content,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MiscNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
