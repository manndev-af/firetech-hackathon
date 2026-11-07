abstract final class ApiEndpoints {
  /// Base URL utama backend server (Satu pusat konfigurasi URL).
  /// Cukup ubah di baris ini untuk mengganti target endpoint seluruh aplikasi.
  static const defaultBaseUrl = 'https://nutrisee.manndev.web.id';

  static const apiPrefix = '/api/v1';
  static const health = '/api/health';
  static const scans = '$apiPrefix/scans';
  static const profile = '$apiPrefix/profile';
  static const foodEntries = '$apiPrefix/food-entries';
  static const dailyNutrition = '$apiPrefix/nutrition/daily';

  static String foodEntryDetail(String id) => '$foodEntries/$id';
  static String foodEntryQuantity(String id) => '$foodEntries/$id/quantity';
}

/// Menentukan base URL backend server dari satu pusat terpadu:
/// 1. Argumen eksplisit pemanggil (misal saat unit test mock)
/// 2. Dart define `--dart-define=API_BASE_URL=...` atau `ANALYSIS_BASE_URL=...`
/// 3. Default tunggal terpusat: `ApiEndpoints.defaultBaseUrl` (https://nutrisee.manndev.web.id)
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
  return ApiEndpoints.defaultBaseUrl;
}
