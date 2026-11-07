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
      final text = (await reader.processImage(InputImage.fromFilePath(path)))
          .text;
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
