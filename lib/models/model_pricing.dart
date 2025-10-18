// Model pricing structure for OpenAI models

class ModelPricing {
  final String name;
  final double inputCostPerMillion;
  final double outputCostPerMillion;

  const ModelPricing({
    required this.name,
    required this.inputCostPerMillion,
    required this.outputCostPerMillion,
  });

  double get inputCostPerToken => inputCostPerMillion / 1000000;
  double get outputCostPerToken => outputCostPerMillion / 1000000;

  /// Calculate total cost for given token usage
  double calculateCost({
    required int promptTokens,
    required int completionTokens,
  }) {
    return (promptTokens * inputCostPerToken) +
        (completionTokens * outputCostPerToken);
  }

  /// Format cost as a string with appropriate currency symbol
  String formatCost({
    required int promptTokens,
    required int completionTokens,
  }) {
    final cost = calculateCost(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
    );

    if (cost < 0.01) {
      return '\$${(cost * 100).toStringAsFixed(4)}¢';
    } else {
      return '\$${cost.toStringAsFixed(4)}';
    }
  }
}
