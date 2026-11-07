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
    expect(find.text('Terverifikasi'), findsOneWidget);

    await tester.tap(find.text('Pilihan B'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(find.text('Terverifikasi'), findsNWidgets(2));

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
    await tester.scrollUntilVisible(
      find.text('Rekomendasi'),
      200,
    );
    expect(find.text('Rekomendasi'), findsOneWidget);
    expect(find.text('Rekomendasi (Mending yang Mana?):'), findsNothing);
    expect(find.textContaining('batasan wajar'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets(
    'shows warning popup when image A is not recognized as food and does not set choice A',
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

  testWidgets(
    'shows warning popup when image B is not recognized as food and does not set choice B',
    (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(
            pickImage: () async => '/test/image_${++callCount}.jpg',
            checkFood: (path) async {
              if (path.contains('image_2')) {
                throw const ScanFailure(
                  'Makanan atau minuman belum terdeteksi. Dekatkan kamera dan ambil foto ulang dengan pencahayaan yang cukup.',
                );
              }
            },
          ),
        ),
      );

      // Select image A successfully
      await tester.tap(find.text('Pilihan A'));
      await tester.pumpAndSettle();
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      // Select image B with invalid non-food image
      await tester.tap(find.text('Pilihan B'));
      await tester.pumpAndSettle();

      // Warning dialog appears for Pilihan B
      expect(find.text('Makanan Belum Terdeteksi'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Foto Ulang'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Foto Ulang'));
      await tester.pumpAndSettle();

      // Dialog is dismissed, Pilihan B was rejected and remains empty
      expect(find.text('Makanan Belum Terdeteksi'), findsNothing);
      expect(find.text('Terverifikasi'), findsOneWidget); // only A is verified
      expect(find.text('Kamera atau galeri'), findsOneWidget); // B still empty
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );

  testWidgets('renders cleanly without overflow on 320px narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: CompareScreen(pickImage: () async => '/test/food.jpg')),
    );

    // Initial state
    expect(tester.takeException(), isNull);

    // Pick both images
    await tester.tap(find.text('Pilihan A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilihan B'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // View comparison summary
    await tester.tap(find.text('Lihat ringkasan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Perbandingan Nutrisi'), 150);
    expect(find.text('Perbandingan Nutrisi'), findsOneWidget);
  });
}
