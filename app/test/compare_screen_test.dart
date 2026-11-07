import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/features/explore/compare_screen.dart';
import 'package:nutrilens/services/local_vision.dart';

void main() {
  testWidgets('shows comparison summary only after both images are selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CompareScreen(pickImage: () async => '/test/food.jpg')),
    );

    expect(
      find.text('Lebih sedikit gula,\nprotein juga berbeda.'),
      findsNothing,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Pilihan A'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Pilihan B'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Lihat ringkasan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lebih sedikit gula,\nprotein juga berbeda.'),
      200,
    );
    expect(
      find.text('Lebih sedikit gula,\nprotein juga berbeda.'),
      findsOneWidget,
    );
    expect(find.text('Bahas pilihan ini'), findsNothing);
    expect(find.text('Ubah gambar'), findsNothing);
    expect(find.text('Perbandingan Nutrisi'), findsOneWidget);
    expect(find.text('Kalori'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets(
    'shows warning popup when image is not recognized as food and does not set choice',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(
            pickImage: () async => '/test/non_food.jpg',
            checkFood: (_) async => throw const ScanFailure(
              'Makanan atau minuman belum terdeteksi. Dekatkan kamera dan ambil foto ulang dengan pencahayaan yang cukup.',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pilihan A'));
      await tester.pumpAndSettle();

      expect(find.text('Makanan Belum Terdeteksi'), findsOneWidget);
      expect(
        find.text(
          'Makanan atau minuman belum terdeteksi. Dekatkan kamera dan ambil foto ulang dengan pencahayaan yang cukup.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Foto Ulang'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Foto Ulang'));
      await tester.pumpAndSettle();

      expect(find.text('Makanan Belum Terdeteksi'), findsNothing);
      expect(find.text('Kamera atau galeri'), findsNWidgets(2));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );
}
