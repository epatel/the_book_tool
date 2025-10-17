class Prompt {
  final int? id;
  final String title;
  final String content;
  final String? response;
  final bool command;
  final bool isTemplate;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Prompt({
    this.id,
    required this.title,
    required this.content,
    this.response,
    this.command = false,
    this.isTemplate = false,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'response': response,
      'command': command ? 1 : 0,
      'is_template': isTemplate ? 1 : 0,
      'order_index': orderIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Prompt.fromMap(Map<String, dynamic> map) {
    return Prompt(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      response: map['response'] as String?,
      command: (map['command'] as int?) == 1,
      isTemplate: (map['is_template'] as int?) == 1,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Prompt copyWith({
    int? id,
    String? title,
    String? content,
    String? response,
    bool? command,
    bool? isTemplate,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      response: response ?? this.response,
      command: command ?? this.command,
      isTemplate: isTemplate ?? this.isTemplate,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
