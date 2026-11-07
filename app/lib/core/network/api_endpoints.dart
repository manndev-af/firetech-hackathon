abstract final class ApiEndpoints {
  static const apiPrefix = '/api/v1';
  static const health = '/api/health';
  static const scans = '$apiPrefix/scans';
  static const profile = '$apiPrefix/profile';
  static const foodEntries = '$apiPrefix/food-entries';
  static const dailyNutrition = '$apiPrefix/nutrition/daily';

  static String foodEntryDetail(String id) => '$foodEntries/$id';
  static String foodEntryQuantity(String id) => '$foodEntries/$id/quantity';
}
