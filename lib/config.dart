import 'package:the_book_tool/index.dart';

// Config for the app
const String openAiModel = 'gpt-5.2';

// Max tokens any backend is allowed to generate for one completion.
const int aiMaxOutputTokens = 4096;

// --- Anthropic ---------------------------------------------------------

const String defaultAnthropicApiUrl = 'https://api.anthropic.com/v1';
const String defaultAnthropicModel = 'claude-opus-5';

// Claude models, most capable first. The Models API is the live source of
// truth; this list is what the dropdown offers before a successful Test.
const List<String> anthropicModelPresets = [
  'claude-opus-5',
  'claude-opus-4-8',
  'claude-sonnet-5',
  'claude-haiku-4-5',
];

// --- Python sidecar ----------------------------------------------------

const String defaultSidecarUrl = 'http://127.0.0.1:8787';
const String defaultSidecarProvider = 'claude-agent-sdk';
const String defaultSidecarModel = 'claude-opus-5';

// Known OpenAI-compatible API URL presets
const Map<String, String> apiUrlPresets = {
  'OpenAI': 'https://api.openai.com/v1',
  'Kimi (Moonshot)': 'https://api.moonshot.ai/v1',
  'DeepSeek': 'https://api.deepseek.com/v1',
  'OpenRouter': 'https://openrouter.ai/api/v1',
  'Together AI': 'https://api.together.xyz/v1',
};

const String defaultApiUrl = 'https://api.openai.com/v1';

// Model presets per provider URL
const Map<String, List<String>> apiModelPresets = {
  'https://api.openai.com/v1': [
    'gpt-5.2',
    'gpt-5.1',
    'gpt-5',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4.1-mini',
    'gpt-4.1-nano',
    'gpt-4o',
    'gpt-4o-mini',
    'o3',
    'o3-mini',
    'o4-mini',
  ],
  'https://api.moonshot.ai/v1': [
    'moonshot-v1-8k',
    'moonshot-v1-32k',
    'moonshot-v1-128k',
  ],
  'https://api.deepseek.com/v1': [
    'deepseek-chat',
    'deepseek-reasoner',
  ],
  'https://openrouter.ai/api/v1': [
    'openai/gpt-5.2',
    'anthropic/claude-sonnet-4',
    'anthropic/claude-haiku-4',
    'google/gemini-2.5-pro',
    'deepseek/deepseek-chat-v3',
    'meta-llama/llama-4-maverick',
  ],
  'https://api.together.xyz/v1': [
    'meta-llama/Llama-4-Maverick-17Bx128E-Instruct-FP8',
    'meta-llama/Llama-4-Scout-17B-16E-Instruct',
    'deepseek-ai/DeepSeek-R1',
    'Qwen/Qwen2.5-72B-Instruct-Turbo',
  ],
};

// Get model presets for a given API URL
List<String> getModelPresetsForUrl(String url) {
  return apiModelPresets[url] ?? [];
}

// Default base URL for a backend
String defaultUrlForBackend(AIBackendKind kind) => switch (kind) {
  AIBackendKind.openAiCompatible => defaultApiUrl,
  AIBackendKind.anthropic => defaultAnthropicApiUrl,
  AIBackendKind.sidecar => defaultSidecarUrl,
};

// Default model for a backend
String defaultModelForBackend(AIBackendKind kind) => switch (kind) {
  AIBackendKind.openAiCompatible => openAiModel,
  AIBackendKind.anthropic => defaultAnthropicModel,
  AIBackendKind.sidecar => defaultSidecarModel,
};

// Model presets to offer for a backend before it has been probed live
List<String> modelPresetsForBackend(AIBackendKind kind, String url) =>
    switch (kind) {
      AIBackendKind.openAiCompatible => getModelPresetsForUrl(url),
      AIBackendKind.anthropic => anthropicModelPresets,
      // The sidecar reports its own models from /health.
      AIBackendKind.sidecar => const [],
    };

// OpenAI model pricing (Standard tier, per 1M tokens)
// Source: https://platform.openai.com/docs/pricing
const Map<String, ModelPricing> modelPricing = {
  // GPT-5 series
  'gpt-5.2': ModelPricing(
    name: 'gpt-5.2',
    inputCostPerMillion: 1.75,
    outputCostPerMillion: 14.00,
  ),
  'gpt-5.1': ModelPricing(
    name: 'gpt-5.1',
    inputCostPerMillion: 1.25,
    outputCostPerMillion: 10.00,
  ),
  'gpt-5': ModelPricing(
    name: 'gpt-5',
    inputCostPerMillion: 1.25,
    outputCostPerMillion: 10.00,
  ),
  'gpt-5-mini': ModelPricing(
    name: 'gpt-5-mini',
    inputCostPerMillion: 0.25,
    outputCostPerMillion: 2.00,
  ),
  'gpt-5-nano': ModelPricing(
    name: 'gpt-5-nano',
    inputCostPerMillion: 0.05,
    outputCostPerMillion: 0.40,
  ),

  // GPT-4.1 series
  'gpt-4.1': ModelPricing(
    name: 'gpt-4.1',
    inputCostPerMillion: 2.00,
    outputCostPerMillion: 8.00,
  ),
  'gpt-4.1-mini': ModelPricing(
    name: 'gpt-4.1-mini',
    inputCostPerMillion: 0.40,
    outputCostPerMillion: 1.60,
  ),
  'gpt-4.1-nano': ModelPricing(
    name: 'gpt-4.1-nano',
    inputCostPerMillion: 0.10,
    outputCostPerMillion: 0.40,
  ),

  // GPT-4o series
  'gpt-4o': ModelPricing(
    name: 'gpt-4o',
    inputCostPerMillion: 2.50,
    outputCostPerMillion: 10.00,
  ),
  'gpt-4o-mini': ModelPricing(
    name: 'gpt-4o-mini',
    inputCostPerMillion: 0.15,
    outputCostPerMillion: 0.60,
  ),

  // o-series (reasoning models)
  'o1': ModelPricing(
    name: 'o1',
    inputCostPerMillion: 15.00,
    outputCostPerMillion: 60.00,
  ),
  'o1-mini': ModelPricing(
    name: 'o1-mini',
    inputCostPerMillion: 1.10,
    outputCostPerMillion: 4.40,
  ),
  'o3': ModelPricing(
    name: 'o3',
    inputCostPerMillion: 2.00,
    outputCostPerMillion: 8.00,
  ),
  'o3-mini': ModelPricing(
    name: 'o3-mini',
    inputCostPerMillion: 1.10,
    outputCostPerMillion: 4.40,
  ),
  'o4-mini': ModelPricing(
    name: 'o4-mini',
    inputCostPerMillion: 1.10,
    outputCostPerMillion: 4.40,
  ),

  // Anthropic (Standard tier, per 1M tokens)
  // Source: https://www.anthropic.com/pricing#api
  'claude-opus-5': ModelPricing(
    name: 'claude-opus-5',
    inputCostPerMillion: 5.00,
    outputCostPerMillion: 25.00,
  ),
  'claude-opus-4-8': ModelPricing(
    name: 'claude-opus-4-8',
    inputCostPerMillion: 5.00,
    outputCostPerMillion: 25.00,
  ),
  'claude-sonnet-5': ModelPricing(
    name: 'claude-sonnet-5',
    inputCostPerMillion: 2.00,
    outputCostPerMillion: 10.00,
  ),
  'claude-haiku-4-5': ModelPricing(
    name: 'claude-haiku-4-5',
    inputCostPerMillion: 1.00,
    outputCostPerMillion: 5.00,
  ),
};

// Helper function to get pricing for a specific model (or default)
ModelPricing getModelPricing(String? model) {
  final modelName = model ?? openAiModel;
  return modelPricing[modelName] ??
      const ModelPricing(
        name: 'gpt-5.2',
        inputCostPerMillion: 1.75,
        outputCostPerMillion: 14.00,
      );
}

// Helper function to get pricing for the default model
ModelPricing getCurrentModelPricing() {
  return getModelPricing(null);
}
