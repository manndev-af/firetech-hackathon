import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/network/api_endpoints.dart';
import '../models/scan_draft.dart';
import '../models/scan_history_entry.dart';
import 'local_vision.dart';

class AnalysisApi {
  AnalysisApi({
    String? baseUrl,
  }) : baseUrl = resolveDefaultBaseUrl(baseUrl);

  final String baseUrl;
  bool get configured => baseUrl.trim().isNotEmpty;

  Future<ScanHistoryEntry> analyze(ScanDraft draft) async {
    if (!configured) {
      throw const ScanFailure(
        'Analisis belum tersedia. Foto dan teks tersimpan di perangkat; kamu bisa mencoba lagi dari Riwayat.',
      );
    }
    final base = Uri.parse(baseUrl);
    final allowHttp = kDebugMode ||
        {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host) ||
        base.host.startsWith('192.168.') ||
        base.host.startsWith('10.');
    if (base.scheme != 'https' && !(allowHttp && base.scheme == 'http')) {
      throw const ScanFailure(
        'Alamat layanan analisis harus menggunakan koneksi aman.',
      );
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      if (kDebugMode) {
        debugPrint('[AnalysisApi] Mengirim permintaan scan ke ${base.resolve(ApiEndpoints.scans)}');
      }
      return await _request(
        client,
        base.resolve(ApiEndpoints.scans),
        draft,
      ).timeout(const Duration(seconds: 45));
    } on ScanFailure {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalysisApi] Gagal menghubungi backend: $e');
      }
      throw const ScanFailure(
        'Analisis belum berhasil. Foto dan teks tetap tersimpan; coba lagi saat koneksi tersedia.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<ScanHistoryEntry> _request(
    HttpClient client,
    Uri uri,
    ScanDraft draft,
  ) async {
    final photo = await File(draft.photoPath).readAsBytes();
    if (photo.length > 5 * 1024 * 1024) {
      throw const ScanFailure(
        'Foto melebihi batas pengiriman (5 MB). Ambil ulang foto.',
      );
    }

    final boundary = '----NutriLensScan${DateTime.now().microsecondsSinceEpoch}';
    final request = await client.postUrl(uri);
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set('Idempotency-Key', draft.id);

    void writeField(String name, String value) {
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
      request.write('$value\r\n');
    }

    // Required field mode
    writeField('mode', draft.label ? 'label' : 'food');

    // Required for label mode
    if (draft.label && draft.rawOcrText != null && draft.rawOcrText!.trim().isNotEmpty) {
      writeField('rawOcrText', draft.rawOcrText!.trim());
    }

    // Optional user note as description
    if (draft.note != null && draft.note!.trim().isNotEmpty) {
      writeField('description', draft.note!.trim());
    }

    writeField('quantity', '1');

    // Write binary image part
    request.write('--$boundary\r\n');
    request.write('Content-Disposition: form-data; name="image"; filename="photo.jpg"\r\n');
    request.write('Content-Type: image/jpeg\r\n\r\n');
    request.add(photo);
    request.write('\r\n');

    // Close boundary
    request.write('--$boundary--\r\n');

    final response = await request.close();
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 512000) {
        throw const FormatException('Response too large');
      }
    }

    final responseBody = utf8.decode(bytes);

    // Accept 201 Created and 200 OK
    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Layanan analisis belum dapat memproses foto. Coba lagi nanti.';
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map && decoded['message'] is String) {
          errorMessage = decoded['message'] as String;
        }
      } catch (_) {}
      throw ScanFailure(errorMessage);
    }

    return parseAnalysisResponse(jsonDecode(responseBody), draft);
  }
}

ScanHistoryEntry parseAnalysisResponse(Object? value, ScanDraft draft) {
  if (value is! Map || value['success'] != true || value['data'] is! Map) {
    throw const FormatException('Invalid analysis response');
  }
  final data = Map<String, dynamic>.from(value['data'] as Map);

  return ScanHistoryEntry.fromBackend(
    data,
    localPhotoPath: draft.photoPath,
    userNote: draft.note,
    prioritySnapshot: draft.priorities,
  );
}
