import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/nutrition_profile.dart';

/// Hasil pembacaan profil dari backend beserta preferensi audio.
class ProfileSyncResult {
  const ProfileSyncResult({
    required this.profile,
    required this.audioEnabled,
  });

  final NutritionProfile profile;
  final bool audioEnabled;
}

/// Service untuk menyinkronkan profil nutrisi dan preferensi audio dengan backend server.
class ProfileApi {
  ProfileApi({
    ApiClient? client,
    String? baseUrl,
  }) : _client = client ??
            ApiClient(
              baseUri: Uri.parse(resolveDefaultBaseUrl(baseUrl)),
            );

  final ApiClient _client;

  /// Mengambil profil nutrisi aktif dari backend.
  Future<ProfileSyncResult?> getProfile() async {
    try {
      final response = await _client.get(ApiEndpoints.profile);
      if (response is Map) {
        final data = Map<String, dynamic>.from(response);
        final profile = NutritionProfile.fromJson(data);
        final audio = data['audioAnalysisEnabled'] as bool? ?? false;
        return ProfileSyncResult(profile: profile, audioEnabled: audio);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Memperbarui kelompok field profil ke backend (identitas, personalisasi, atau audio).
  Future<ProfileSyncResult?> patchProfile(Map<String, dynamic> delta) async {
    try {
      final response = await _client.patch(
        ApiEndpoints.profile,
        body: delta,
      );
      if (response is Map) {
        final data = Map<String, dynamic>.from(response);
        final profile = NutritionProfile.fromJson(data);
        final audio = data['audioAnalysisEnabled'] as bool? ?? false;
        return ProfileSyncResult(profile: profile, audioEnabled: audio);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
