import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/scan_draft.dart';
import '../models/scan_history_entry.dart';
import 'local_vision.dart';

class AnalysisApi {
  AnalysisApi({
    this.baseUrl = const String.fromEnvironment('ANALYSIS_BASE_URL'),
  });
  final String baseUrl;
  bool get configured => baseUrl.trim().isNotEmpty;

  Future<ScanHistoryEntry> analyze(ScanDraft draft) async {
    if (!configured) {
      throw const ScanFailure(
        'Analisis belum tersedia. Foto dan teks tersimpan di perangkat; kamu bisa mencoba lagi dari Riwayat.',
      );
    }
    final base = Uri.parse(baseUrl);
    final localDebug =
        kDebugMode &&
        {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host);
    if (base.scheme != 'https' && !(localDebug && base.scheme == 'http')) {
      throw const ScanFailure(
        'Alamat layanan analisis harus menggunakan koneksi aman.',
      );
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      return await _request(
        client,
        base.resolve('/api/v1/analysis'),
        draft,
      ).timeout(const Duration(seconds: 45));
    } on ScanFailure {
      rethrow;
    } catch (_) {
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
    if (photo.length > 1500000) {
      throw const ScanFailure(
        'Foto melebihi batas pengiriman. Ambil ulang foto.',
      );
    }
    final request = await client.postUrl(uri);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set('Idempotency-Key', draft.id);
    request.write(
      jsonEncode({
        'requestId': draft.id,
        'mode': draft.label ? 'label' : 'food',
        'rawOcrText': draft.rawOcrText,
        if (draft.note != null && draft.note!.trim().isNotEmpty)
          'userNote': draft.note!.trim(),
        'image': {'mimeType': 'image/jpeg', 'base64': base64Encode(photo)},
        'priorities': draft.priorities,
      }),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      throw const ScanFailure(
        'Layanan analisis belum dapat memproses foto. Coba lagi nanti.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 256000) {
        throw const FormatException('Response too large');
      }
    }
    return parseAnalysisResponse(jsonDecode(utf8.decode(bytes)), draft);
  }
}

ScanHistoryEntry parseAnalysisResponse(Object? value, ScanDraft draft) {
  if (value is! Map || value['success'] != true || value['data'] is! Map) {
    throw const FormatException('Invalid analysis response');
  }
  final data = value['data'] as Map;
  String text(String key, {int max = 4000}) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty || value.length > max) {
      throw FormatException('Invalid $key');
    }
    return value.trim();
  }

  final nutrients = data['nutrients'];
  if (nutrients is! Map) throw const FormatException('Missing nutrients');
  double? nutrient(String key) {
    final value = nutrients[key];
    if (value == null) return null;
    if (value is! num || !value.isFinite || value < 0) {
      throw FormatException('Invalid $key');
    }
    return value.toDouble();
  }

  final spoken = data['spokenSummary'];
  if (spoken != null && (spoken is! String || spoken.length > 320)) {
    throw const FormatException('Invalid spoken summary');
  }
  return ScanHistoryEntry(
    id: draft.id,
    name: text('foodName', max: 160),
    savedAt: draft.createdAt,
    packaged: draft.label,
    portion: text('portion', max: 200),
    source: text('source'),
    referenceBasis: text('referenceBasis', max: 300),
    energyKcal: nutrient('energyKcal'),
    proteinG: nutrient('proteinG'),
    sugarG: nutrient('sugarG'),
    sodiumMg: nutrient('sodiumMg'),
    note: text('summary'),
    userNote: draft.note,
    spokenSummary: spoken is String && spoken.trim().isNotEmpty
        ? spoken.trim()
        : 'Hasil analisis sudah tersedia. Periksa nama makanan, porsi, dan informasi yang belum lengkap sebelum menggunakannya.',
    photoPath: draft.photoPath,
    rawOcrText: draft.rawOcrText,
    prioritySnapshot: draft.priorities,
  );
}
