import 'dart:ui';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanFailure implements Exception {
  const ScanFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class VisionLabel {
  const VisionLabel(this.text, this.confidence);
  final String text;
  final double confidence;
}

abstract final class LocalVisionService {
  static bool containsNutritionKeywords(String text) =>
      _hasNutritionKeywords(text);
}

bool containsNutritionKeywords(String text) => _hasNutritionKeywords(text);

bool _hasNutritionKeywords(String text) {
  final lower = text.toLowerCase();
  const keywords = [
    'informasi nilai gizi',
    'nilai gizi',
    'nutrition facts',
    'nutrition information',
    'takaran saji',
    'sajian per kemasan',
    'jumlah per sajian',
    'serving size',
    'servings per container',
    'energi total',
    'energi',
    'kalori',
    'calories',
    'energy',
    'kkal',
    'kcal',
    'lemak total',
    'lemak jenuh',
    'lemak',
    'fat',
    'saturated fat',
    'protein',
    'karbohidrat total',
    'karbohidrat',
    'carbohydrate',
    'gula',
    'sugar',
    'sugars',
    'natrium',
    'sodium',
    'garam',
    'salt',
  ];
  return keywords.any((k) => lower.contains(k));
}

/// Initial tunable policy, not a measured accuracy guarantee. Do not accept
/// containers such as Cup/Bottle: an empty cup is not evidence of a drink.
bool acceptsFoodPhoto(
  Iterable<VisionLabel> objects,
  Iterable<VisionLabel> labels, {
  double threshold = .65,
}) {
  const beverages = {
    'juice',
    'cola',
    'coffee',
    'wine',
    'cappuccino',
    'tea',
    'milk',
    'drink',
    'beverage',
    'smoothie',
    'soda',
    'soft drink',
    'espresso',
    'latte',
    'cocktail',
    'beer',
    'milkshake',
    'hot chocolate',
    'water',
  };
  const foodLabels = {
    'food',
    'dish',
    'cuisine',
    'meal',
    'fast food',
    'snack',
    'dessert',
    'fruit',
    'vegetable',
    'soup',
    'noodle',
    'rice',
    'meat',
    'seafood',
    'bread',
    'salad',
  };
  bool confident(VisionLabel label) =>
      label.confidence.isFinite &&
      label.confidence >= threshold &&
      label.confidence <= 1;
  return objects.any(
        (label) => label.text.toLowerCase() == 'food' && confident(label),
      ) ||
      labels.any(
        (label) =>
            (beverages.contains(label.text.toLowerCase()) ||
                foodLabels.contains(label.text.toLowerCase())) &&
            confident(label),
      );
}

class LocalVision {
  Future<void> checkFood(String path) async {
    final detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: .65),
    );
    try {
      final input = InputImage.fromFilePath(path);
      final objects = await detector.processImage(input);
      final objectLabels = objects
          .expand((object) => object.labels)
          .map((label) => VisionLabel(label.text, label.confidence))
          .toList();
      if (acceptsFoodPhoto(objectLabels, const [])) return;
      final labels = await labeler.processImage(input);
      if (!acceptsFoodPhoto(
        objectLabels,
        labels.map((label) => VisionLabel(label.label, label.confidence)),
      )) {
        throw const ScanFailure(
          'Makanan atau minuman belum terdeteksi. Dekatkan kamera dan ambil foto ulang dengan pencahayaan yang cukup.',
        );
      }
    } on ScanFailure {
      rethrow;
    } catch (_) {
      throw const ScanFailure(
        'Pemeriksaan foto belum berhasil. Coba lagi setelah model perangkat siap. Foto belum dikirim.',
      );
    } finally {
      await detector.close();
      await labeler.close();
    }
  }

  Future<String> readText(String path) async {
    final reader = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized =
          await reader.processImage(InputImage.fromFilePath(path));
      final text = formatRecognizedTextAsRows(recognized);
      if (text.trim().isEmpty) {
        throw const ScanFailure(
          'Teks label belum terbaca. Foto ulang label dengan lebih dekat.',
        );
      }
      return text;
    } on ScanFailure {
      rethrow;
    } catch (_) {
      throw const ScanFailure(
        'Label belum berhasil dibaca di perangkat. Coba foto ulang.',
      );
    } finally {
      await reader.close();
    }
  }
}

/// Memformat teks hasil Google ML Kit ke dalam susunan baris horizontal (kiri-ke-kanan).
/// Bermanfaat khusus untuk tabel Informasi Nilai Gizi di mana nama kandungan berada di kiri
/// dan nominal/satuan berada di kolom kanan, sehingga tidak terpisah ke blok yang berbeda.
String formatRecognizedTextAsRows(RecognizedText recognizedText) {
  final allLines = recognizedText.blocks.expand((b) => b.lines).toList();
  if (allLines.isEmpty) return recognizedText.text.trim();

  final items = allLines
      .map((line) => (
            text: line.text,
            boundingBox: line.boundingBox,
          ))
      .toList();

  return formatTextLinesAsRows(items, fallbackText: recognizedText.text);
}

/// Mengelompokkan potongan baris teks berdasarkan kedekatan vertikal (sumbu Y)
/// lalu mengurutkan setiap baris dari kiri ke kanan (sumbu X).
String formatTextLinesAsRows(
  List<({String text, Rect boundingBox})> items, {
  String fallbackText = '',
}) {
  if (items.isEmpty) return fallbackText.trim();

  // 1. Ekstrak teks, posisi tengah vertikal (centerY), dan tinggi baris
  final mapped = items
      .map((item) {
        final box = item.boundingBox;
        final height = (box.bottom - box.top).abs();
        final centerY = (box.top + box.bottom) / 2.0;
        return (
          text: item.text.trim(),
          box: box,
          centerY: centerY,
          height: height > 0 ? height : 16.0,
        );
      })
      .where((i) => i.text.isNotEmpty)
      .toList();

  if (mapped.isEmpty) return fallbackText.trim();

  // 2. Urutkan berdasarkan posisi vertikal terlebih dahulu
  mapped.sort((a, b) => a.centerY.compareTo(b.centerY));

  // 3. Kelompokkan elemen yang sejajar secara horizontal ke dalam baris yang sama
  final rows = <List<({String text, Rect box, double centerY, double height})>>[];

  for (final item in mapped) {
    bool added = false;
    for (final row in rows) {
      final avgCenter =
          row.map((e) => e.centerY).reduce((a, b) => a + b) / row.length;
      final avgHeight =
          row.map((e) => e.height).reduce((a, b) => a + b) / row.length;
      final threshold = avgHeight * 0.6;

      if ((item.centerY - avgCenter).abs() <= threshold) {
        row.add(item);
        added = true;
        break;
      }
    }
    if (!added) {
      rows.add([item]);
    }
  }

  // 4. Urutkan baris-baris dari atas ke bawah
  rows.sort((a, b) {
    final avgA = a.map((e) => e.centerY).reduce((x, y) => x + y) / a.length;
    final avgB = b.map((e) => e.centerY).reduce((x, y) => x + y) / b.length;
    return avgA.compareTo(avgB);
  });

  // 5. Untuk setiap baris, urutkan elemen dari kiri ke kanan dan gabungkan
  final buffer = StringBuffer();
  for (final row in rows) {
    row.sort((a, b) => a.box.left.compareTo(b.box.left));
    final rowText = row.map((e) => e.text).join('  ');
    if (rowText.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(rowText);
    }
  }

  final result = buffer.toString().trim();
  return result.isNotEmpty ? result : fallbackText.trim();
}
