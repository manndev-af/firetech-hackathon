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

/// Menentukan base URL backend default.
/// Prioritas:
/// 1. Argumen eksplisit pemanggil
/// 2. Dart define `--dart-define=API_BASE_URL=...` atau `ANALYSIS_BASE_URL=...`
/// 3. Default `http://localhost:3000` (kompatibel langsung dengan desktop Windows, web,
///    dan device Android fisik melalui `adb reverse tcp:3000 tcp:3000`).
String resolveDefaultBaseUrl([String? explicitUrl]) {
  if (explicitUrl != null && explicitUrl.trim().isNotEmpty) {
    return explicitUrl.trim();
  }
  const envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment('ANALYSIS_BASE_URL'),
  );
  if (envUrl.trim().isNotEmpty) {
    return envUrl.trim();
  }
  return 'http://localhost:3000';
}
