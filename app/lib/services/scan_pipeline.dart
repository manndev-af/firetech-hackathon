import 'dart:io';
import 'dart:typed_data';

import '../core/utils/uuid_generator.dart';
import '../models/scan_draft.dart';
import 'local_storage.dart';
import 'local_vision.dart';
import 'scan_image.dart';

class ScanPipeline {
  ScanPipeline({
    required this.storage,
    this.requireRawOcr = const bool.fromEnvironment('SCANNER_USE_RAW_OCR'),
    Future<void> Function(String)? checkFood,
    Future<String> Function(String)? readText,
    Future<Uint8List> Function(String, bool)? resize,
  }) : checkFood = checkFood ?? LocalVision().checkFood,
       readText = readText ?? LocalVision().readText,
       resize =
           resize ?? ((path, label) => prepareScanImage(path, label: label));
  final LocalStorage storage;
  final bool requireRawOcr;
  final Future<void> Function(String) checkFood;
  final Future<String> Function(String) readText;
  final Future<Uint8List> Function(String, bool) resize;

  Future<ScanDraft> prepare(
    String path, {
    required bool label,
    required List<String> priorities,
    String? note,
  }) async {
    if (await File(path).length() > 20000000) {
      throw const ScanFailure('Ukuran foto maksimal 20 MB.');
    }
    // Mode label deliberately skips the food gate; label photos may contain only text.
    String? rawText;
    if (label) {
      try {
        rawText = await readText(path);
      } on ScanFailure {
        if (requireRawOcr) rethrow;
        // The backend vision call can read the image when local OCR fails.
      }
    }
    if (rawText != null && rawText.length > 20000) {
      throw const ScanFailure(
        'Teks terlalu panjang. Foto hanya bagian label produk.',
      );
    }
    if (label && requireRawOcr && (rawText == null || rawText.trim().isEmpty)) {
      throw const ScanFailure('Teks label belum terbaca. Ambil ulang foto.');
    }
    if (label && requireRawOcr && !containsNutritionKeywords(rawText!)) {
      throw const ScanFailure(
        'Tabel nilai gizi tidak ditemukan pada label. Pastikan memotret bagian Informasi Nilai Gizi (Nutrition Facts) produk.',
      );
    }
    if (!label) await checkFood(path);
    final bytes = await resize(path, label);
    final id = generateUuidV4();
    final folder = Directory('${storage.directory.path}/photos');
    await folder.create(recursive: true);
    final photo = File('${folder.path}/$id.jpg');
    await photo.writeAsBytes(bytes, flush: true);
    return ScanDraft(
      id: id,
      photoPath: photo.path,
      label: label,
      createdAt: DateTime.now(),
      priorities: List.of(priorities),
      rawOcrText: rawText,
      note: note,
    );
  }
}
