// The AI backends the app can talk to.
//
// Each kind maps to an [AIBackend] implementation in lib/services/ai_backends/.
// The selected kind is stored in the manifest under the key `AIBackend`.
enum AIBackendKind {
  /// OpenAI and any OpenAI-compatible endpoint (Kimi, DeepSeek, OpenRouter...).
  openAiCompatible,

  /// Anthropic Messages API, called directly over HTTPS.
  anthropic,

  /// A local Python sidecar process that fronts anything it likes
  /// (Claude Agent SDK, litellm, local models).
  sidecar;

  static AIBackendKind fromString(String? value) {
    return AIBackendKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => AIBackendKind.openAiCompatible,
    );
  }

  String get displayName => switch (this) {
    AIBackendKind.openAiCompatible => 'OpenAI compatible',
    AIBackendKind.anthropic => 'Anthropic API',
    AIBackendKind.sidecar => 'Python sidecar',
  };

  String get description => switch (this) {
    AIBackendKind.openAiCompatible =>
      'OpenAI, or any endpoint speaking the OpenAI chat-completions API.',
    AIBackendKind.anthropic =>
      'Claude models called directly on api.anthropic.com.',
    AIBackendKind.sidecar =>
      'A local Python server you run yourself. Use it for the Claude Agent '
          'SDK or any provider Python can reach.',
  };

  /// Whether the backend authenticates with a key held in secure storage.
  bool get usesApiKey => this != AIBackendKind.sidecar;

  /// Whether the user can point the backend at an arbitrary base URL.
  bool get usesApiUrl => true;

  /// Key under which this backend's credential lives in secure storage.
  String get secureStorageKey => switch (this) {
    AIBackendKind.openAiCompatible => 'openai_api_key',
    AIBackendKind.anthropic => 'anthropic_api_key',
    AIBackendKind.sidecar => 'sidecar_token',
  };

  /// Manifest key holding the selected model for this backend.
  String get modelManifestKey => switch (this) {
    AIBackendKind.openAiCompatible => 'AIModel',
    AIBackendKind.anthropic => 'AIAnthropicModel',
    AIBackendKind.sidecar => 'AISidecarModel',
  };

  /// Manifest key holding the base URL for this backend.
  String get urlManifestKey => switch (this) {
    AIBackendKind.openAiCompatible => 'AIApiUrl',
    AIBackendKind.anthropic => 'AIAnthropicApiUrl',
    AIBackendKind.sidecar => 'AISidecarUrl',
  };
}
