import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/services/local_vision.dart';

void main() {
  group('formatTextLinesAsRows', () {
    test('merges two separate columns into aligned row-by-row nutrition facts', () {
      // Skenario nyata ML Kit:
      // Kolom 1 (kiri): Nama kandungan
      // Kolom 2 (kanan): Nilai/nominal
      final items = <({String text, Rect boundingBox})>[
        // Kolom Kiri
        (
          text: 'Takaran Saji',
          boundingBox: const Rect.fromLTWH(40, 50, 120, 20),
        ),
        (
          text: 'Lemak Total',
          boundingBox: const Rect.fromLTWH(40, 80, 110, 20),
        ),
        (
          text: 'Protein',
          boundingBox: const Rect.fromLTWH(40, 110, 70, 20),
        ),
        (
          text: 'Karbohidrat Total',
          boundingBox: const Rect.fromLTWH(40, 140, 140, 20),
        ),
        (
          text: 'Gula',
          boundingBox: const Rect.fromLTWH(40, 170, 50, 20),
        ),
        (
          text: 'Natrium',
          boundingBox: const Rect.fromLTWH(40, 200, 70, 20),
        ),

        // Kolom Kanan (letaknya terpisah jauh di kanan, tapi sejajar secara Y)
        (
          text: '100 g',
          boundingBox: const Rect.fromLTWH(300, 51, 50, 19),
        ),
        (
          text: '2 g',
          boundingBox: const Rect.fromLTWH(300, 79, 30, 21),
        ),
        (
          text: '8 g',
          boundingBox: const Rect.fromLTWH(300, 111, 30, 19),
        ),
        (
          text: '24 g',
          boundingBox: const Rect.fromLTWH(300, 139, 40, 20),
        ),
        (
          text: '6 g',
          boundingBox: const Rect.fromLTWH(300, 169, 30, 20),
        ),
        (
          text: '50 mg',
          boundingBox: const Rect.fromLTWH(300, 202, 50, 19),
        ),
      ];

      final formatted = formatTextLinesAsRows(items);
      final lines = formatted.split('\n');

      expect(lines, hasLength(6));
      expect(lines[0], 'Takaran Saji  100 g');
      expect(lines[1], 'Lemak Total  2 g');
      expect(lines[2], 'Protein  8 g');
      expect(lines[3], 'Karbohidrat Total  24 g');
      expect(lines[4], 'Gula  6 g');
      expect(lines[5], 'Natrium  50 mg');
    });

    test('supports 3 columns (Name, Value, % AKG) in correct left-to-right order', () {
      final items = <({String text, Rect boundingBox})>[
        (text: 'Protein', boundingBox: const Rect.fromLTWH(30, 100, 60, 20)),
        (text: '12%', boundingBox: const Rect.fromLTWH(350, 101, 35, 19)),
        (text: '9 g', boundingBox: const Rect.fromLTWH(200, 99, 30, 21)),
      ];

      final formatted = formatTextLinesAsRows(items);
      expect(formatted, 'Protein  9 g  12%');
    });

    test('falls back gracefully on empty or single line input', () {
      expect(formatTextLinesAsRows([]), '');
      expect(formatTextLinesAsRows([], fallbackText: 'fallback text'), 'fallback text');

      final single = [
        (text: 'INFORMASI NILAI GIZI', boundingBox: const Rect.fromLTWH(50, 20, 200, 25)),
      ];
      expect(formatTextLinesAsRows(single), 'INFORMASI NILAI GIZI');
    });
  });
}
