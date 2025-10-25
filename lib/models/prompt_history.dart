class PromptHistory {
  final int? id;
  final String promptText;
  final String? responseText;
  final String contextType;
  final int? contextId;
  final String contextName;
  final bool wasCommand;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? model;
  final int createdAt;

  PromptHistory({
    this.id,
    required this.promptText,
    this.responseText,
    required this.contextType,
    this.contextId,
    required this.contextName,
    required this.wasCommand,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.model,
    required this.createdAt,
  });

  factory PromptHistory.fromMap(Map<String, dynamic> map) {
    return PromptHistory(
      id: map['id'] as int?,
      promptText: map['prompt_text'] as String,
      responseText: map['response_text'] as String?,
      contextType: map['context_type'] as String,
      contextId: map['context_id'] as int?,
      contextName: map['context_name'] as String,
      wasCommand: (map['was_command'] as int) == 1,
      promptTokens: map['prompt_tokens'] as int?,
      completionTokens: map['completion_tokens'] as int?,
      totalTokens: map['total_tokens'] as int?,
      model: map['model'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'prompt_text': promptText,
      'response_text': responseText,
      'context_type': contextType,
      'context_id': contextId,
      'context_name': contextName,
      'was_command': wasCommand ? 1 : 0,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'model': model,
      'created_at': createdAt,
    };
  }

  PromptHistory copyWith({
    int? id,
    String? promptText,
    String? responseText,
    String? contextType,
    int? contextId,
    String? contextName,
    bool? wasCommand,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? model,
    int? createdAt,
  }) {
    return PromptHistory(
      id: id ?? this.id,
      promptText: promptText ?? this.promptText,
      responseText: responseText ?? this.responseText,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      contextName: contextName ?? this.contextName,
      wasCommand: wasCommand ?? this.wasCommand,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
