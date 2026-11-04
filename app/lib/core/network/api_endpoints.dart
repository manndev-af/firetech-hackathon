abstract final class ApiEndpoints {
  static const apiPrefix = '/api/v1';
  static const health = '$apiPrefix/health';
  static const classifyFood = '$apiPrefix/food/classify';
  static const analyzeNutrition = '$apiPrefix/nutrition/analyze';
  static const compareNutrition = '$apiPrefix/nutrition/compare';
  static const parseLabel = '$apiPrefix/label/parse';
  static const analyzeTradeoff = '$apiPrefix/tradeoff/analyze';
}
