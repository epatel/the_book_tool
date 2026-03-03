import 'package:the_book_tool/index.dart';

// Config for the app
const String openAiModel = 'gpt-5.2';

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
