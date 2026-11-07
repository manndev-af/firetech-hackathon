import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/features/scanner/scan_result_screen.dart';
import 'package:nutrilens/features/scanner/scanner_screen.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('available primary nutrients only, text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: ScanResultScreen(photo: XFile('/missing.jpg'), mode: ScanMode.label,
          readText: (_) async => 'Energi 120 kkal\nProtein 0 g\nLemak total 4 g'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nutrient-card-Energi')), findsOneWidget);
      expect(find.byKey(const ValueKey('nutrient-card-Protein')), findsOneWidget);
      expect(find.byKey(const ValueKey('nutrient-card-Gula')), findsNothing);
      expect(find.byKey(const ValueKey('nutrient-card-Lemak total')), findsNothing);
      expect(find.text('Belum tersedia: Gula, Natrium.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
