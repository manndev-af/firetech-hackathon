import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/app.dart';
import 'package:nutrilens/core/router/app_router.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/history/history_screen.dart';
import 'package:nutrilens/features/explore/assistant_screen.dart';
import 'package:nutrilens/features/explore/compare_screen.dart';
import 'package:nutrilens/features/explore/explore_screen.dart';
import 'package:nutrilens/features/profile/nutrition_profile_screen.dart';
import 'package:nutrilens/features/profile/profile_screen.dart';
import 'package:nutrilens/models/nutrition_profile.dart';

void main() {
  Future<void> tap(WidgetTester tester, String text) async {
    await tester.pumpAndSettle();
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('profile saves multiple priorities and survives tab changes', (
    tester,
  ) async {
    profileSession.value = NutritionProfile(
      priorities: ['Protein'],
      preference: 'Masakan rumahan',
    );
    appRouter.go(AppRoutes.home);
    await tester.pumpWidget(const NutriLensApp());
    await tester.pumpAndSettle();
    await tap(tester, 'Profile');
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tap(tester, 'Edit profil nutrisi');
    await tester.enterText(find.byType(TextFormField).at(0), 'Naya');
    await tester.enterText(find.byType(TextFormField).at(1), '22');
    await tap(tester, 'Gula');
    await tap(tester, 'Kalori');
    await tap(tester, 'Kosongkan preferensi');
    await tap(tester, 'Simpan profil');
    expect(profileSession.value.name, 'Naya');
    expect(profileSession.value.age, 22);
    expect(profileSession.value.priorities, ['Gula', 'Protein', 'Kalori']);
    expect(profileSession.value.preference, isNull);
    await tap(tester, 'History');
    expect(find.byType(HistoryScreen), findsOneWidget);
    await tap(tester, 'Profile');
    expect(find.text('Naya'), findsOneWidget);
    await tap(tester, 'Edit profil nutrisi');
    await tester.enterText(find.byType(TextFormField).first, 'Tidak disimpan');
    await tap(tester, 'Batal');
    expect(profileSession.value.name, 'Naya');
    await tap(tester, 'Jelajahi');
    expect(find.byType(ExploreScreen), findsOneWidget);
    await tap(tester, 'Bandingkan dua pilihan');
    expect(find.byType(CompareScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tap(tester, 'Lihat pola catatanku');
    expect(find.byType(AssistantScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tap(tester, 'Tanya soal makanan');
    expect(find.byType(AssistantScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid age and empty priorities prevent saving; optional age can clear',
    (tester) async {
      NutritionProfile? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NutritionProfileScreen(
            profile: NutritionProfile(),
            onSave: (value) => saved = value,
            onCancel: () {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(1), '-2');
      await tap(tester, 'Simpan profil');
      expect(saved, isNull);
      expect(find.text('Pilih minimal satu prioritas.'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextFormField).at(1));
      expect(find.text('Isi usia 1–120 tahun atau kosongkan.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tap(tester, 'Keseimbangan');
      await tap(tester, 'Simpan profil');
      expect(saved?.age, isNull);
      expect(saved?.name, '');
      expect(saved?.priorities, ['Keseimbangan']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history filters reset and scan never creates a fake record', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HistoryScreen()),
    );
    expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    await tap(tester, 'Kemasan');
    expect(find.text('Belum ada hasil yang sesuai'), findsOneWidget);
    await tap(tester, 'Semua tanggal');
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tap(tester, 'Pilih');
    expect(find.text('Semua tanggal'), findsNothing);
    await tap(tester, 'Reset filter');
    expect(find.text('Semua tanggal'), findsOneWidget);
    expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    await tap(tester, 'Mulai pindai');
    expect(find.text('Kamera makanan belum tersedia.'), findsOneWidget);
    expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile and history reflow at 320px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final screen in <Widget>[
      ProfileScreen(
        profile: NutritionProfile(
          name: 'Nama panjang pengguna NutriLens',
          priorities: NutritionProfile.priorityOptions,
        ),
        onEdit: () {},
      ),
      NutritionProfileScreen(
        profile: NutritionProfile(),
        onSave: (_) {},
        onCancel: () {},
      ),
      const HistoryScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
