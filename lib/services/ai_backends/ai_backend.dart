import 'package:the_book_tool/index.dart';

/// One completion request, already assembled by [AIService].
///
/// Backends receive a fully-built system message and user prompt; they know
/// nothing about chapters, characters or command mode.
class AIBackendRequest {
  final String systemMessage;
  final String prompt;
  final String model;
  final int maxTokens;

  const AIBackendRequest({
    required this.systemMessage,
    required this.prompt,
    required this.model,
    this.maxTokens = aiMaxOutputTokens,
  });
}

/// The raw text a backend produced, plus whatever usage it reported.
///
/// [costUsd] is only set by backends that price the call themselves (the
/// sidecar does). When it is null, cost is derived from [modelPricing].
class AIBackendResult {
  final String content;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? model;
  final double? costUsd;

  const AIBackendResult({
    required this.content,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.model,
    this.costUsd,
  });
}

/// Result of a connectivity check, shown in the settings dialog.
class AIBackendHealth {
  final bool ok;
  final String message;

  /// Models the backend reports it can serve, when it can tell us.
  final List<String> models;

  const AIBackendHealth({
    required this.ok,
    required this.message,
    this.models = const [],
  });
}

/// Raised when a backend fails in a way worth showing the user.
class AIBackendException implements Exception {
  final String message;

  const AIBackendException(this.message);

  @override
  String toString() => message;
}

/// A source of completions. One implementation per [AIBackendKind].
abstract class AIBackend {
  AIBackendKind get kind;

  /// Send one prompt and wait for the whole response.
  Future<AIBackendResult> send(AIBackendRequest request);

  /// Check that the backend is reachable and configured.
  Future<AIBackendHealth> check();

  /// Release any held clients or sockets.
  void dispose() {}
}
