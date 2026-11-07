import 'dart:io';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/scan_history_entry.dart';

/// Service untuk berkomunikasi dengan endpoint jurnal konsumsi dan nutrisi harian backend.
class JournalApi {
  JournalApi({
    ApiClient? client,
    String? baseUrl,
  }) : _client = client ??
            ApiClient(
              baseUri: Uri.parse(resolveDefaultBaseUrl(baseUrl)),
            );

  final ApiClient _client;

  /// Mengambil daftar riwayat entri konsumsi dari backend.
  Future<List<ScanHistoryEntry>> listEntries({
    String? date,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
      };
      final uri = Uri(path: ApiEndpoints.foodEntries, queryParameters: queryParams);
      final response = await _client.get(uri.toString());

      if (response is Map && response['entries'] is List) {
        final entriesList = response['entries'] as List;
        return entriesList
            .whereType<Map>()
            .map((e) => ScanHistoryEntry.fromBackend(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Mengambil detail satu entri konsumsi berdasarkan ID.
  Future<ScanHistoryEntry?> getEntry(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.foodEntryDetail(id));
      if (response is Map) {
        return ScanHistoryEntry.fromBackend(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Memperbarui porsi kuantitas entri konsumsi secara deterministik di backend.
  Future<ScanHistoryEntry?> updateQuantity(String id, double quantity) async {
    try {
      final response = await _client.patch(
        ApiEndpoints.foodEntryQuantity(id),
        body: {'quantity': quantity},
      );
      if (response is Map) {
        return ScanHistoryEntry.fromBackend(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Menghapus catatan konsumsi dari backend.
  Future<bool> deleteEntry(String id) async {
    try {
      await _client.delete(ApiEndpoints.foodEntryDetail(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil ringkasan nutrisi harian dari backend.
  Future<Map<String, dynamic>?> getDailyNutrition({String? date}) async {
    try {
      final queryParams = date != null && date.isNotEmpty ? '?date=$date' : '';
      final response = await _client.get('${ApiEndpoints.dailyNutrition}$queryParams');
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
