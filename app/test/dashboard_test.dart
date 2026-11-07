import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/dashboard/dashboard_screen.dart';
import 'package:nutrilens/features/dashboard/widgets/dashboard_history.dart';
import 'package:nutrilens/models/daily_nutrition_summary.dart';

void main() {
  Future<void> showDashboard(
    WidgetTester tester, {
    DailyNutritionSummary? summary,
    VoidCallback? onScan,
    VoidCallback? onExplore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DashboardScreen(
          summary: summary,
          focus: 'Protein',
          now: DateTime(2026, 11, 7, 9),
          onScan: onScan,
          onExplore: onExplore,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty dashboard never invents food records or nutrient totals', (
    tester,
  ) async {
    var scans = 0;
    await showDashboard(tester, onScan: () => scans++);
    expect(find.text('SELAMAT PAGI'), findsOneWidget);
    expect(find.text('FOKUSMU · PROTEIN'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsOneWidget);
    expect(find.text('Mulai dengan satu makanan.'), findsOneWidget);
    expect(find.text('18 g'), findsNothing);
    expect(find.text('Energi'), findsNothing);
    await tester.ensureVisible(find.text('Foto makanan'));
    await tester.tap(find.text('Foto makanan'));
    await tester.ensureVisible(find.text('Catat makanan pertama'));
    await tester.tap(find.text('Catat makanan pertama'));
    expect(scans, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'populated history displays supplied totals and incomplete-data notice',
    (tester) async {
      var explored = false;
      await showDashboard(
        tester,
        summary: const DailyNutritionSummary(
          recordCount: 2,
          sugarG: 7.5,
          proteinG: 21,
          energyKcal: 410,
          sugarComplete: false,
        ),
        onExplore: () => explored = true,
      );
      expect(find.text('2 catatan'), findsOneWidget);
      expect(find.text('7.5 g'), findsOneWidget);
      expect(find.text('21 g'), findsOneWidget);
      expect(find.text('410 kkal'), findsOneWidget);
      expect(
        find.text('Catatan hari ini · data gula belum lengkap.'),
        findsOneWidget,
      );
      expect(find.text('Catat makanan pertama'), findsNothing);
      final explore = find.text('Buka Jelajah  →');
      await tester.ensureVisible(explore);
      await tester.tap(explore);
      expect(explored, isTrue);
    },
  );

  testWidgets('missing nutrient stays unknown while a real zero stays zero', (
    tester,
  ) async {
    await showDashboard(
      tester,
      summary: const DailyNutritionSummary(
        recordCount: 1,
        sugarG: null,
        proteinG: 0,
        energyKcal: 125,
      ),
    );
    expect(find.text('Belum tersedia'), findsOneWidget);
    expect(find.text('0 g'), findsOneWidget);
    expect(
      find.text('Catatan hari ini · data gula belum lengkap.'),
      findsOneWidget,
    );
    expect(find.byType(DashboardHistory), findsOneWidget);
  });

  testWidgets(
    'unimplemented camera reports its status without adding fake history',
    (tester) async {
      await showDashboard(tester);
      await tester.ensureVisible(find.text('Foto makanan'));
      await tester.tap(find.text('Foto makanan'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera makanan belum tersedia.'), findsOneWidget);
      expect(find.text('Belum ada catatan'), findsOneWidget);
    },
  );

  testWidgets('dashboard reflows at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const DashboardScreen(
            summary: DailyNutritionSummary(
              recordCount: 1,
              sugarG: null,
              proteinG: 12.5,
              energyKcal: 200,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buka Jelajah  →'));
    expect(tester.takeException(), isNull);
    expect(find.text('FOKUSMU · BELUM DIPILIH'), findsOneWidget);
  });
}
