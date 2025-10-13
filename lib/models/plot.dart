class Plot {
  final int? id;
  final String title;
  final String description;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plot({
    this.id,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Plot copyWith({
    int? id,
    String? title,
    String? description,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plot(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
