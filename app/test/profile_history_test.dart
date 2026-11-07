import 'dart:io';

import 'package:nutrilens/shared/widgets/personal_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:nutrilens/models/history_preview_data.dart';
import 'package:nutrilens/features/history/widgets/history_entry_card.dart';
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
import 'package:nutrilens/models/scan_history_entry.dart';

void main() {
  Future<void> tap(WidgetTester tester, String text) async {
    await tester.pumpAndSettle();
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String value) async {
    final field = find.byKey(Key(key));
    if (field.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        field,
        200,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
    }
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
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
    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    await enter(tester, 'profile-name', 'Naya');
    await enter(tester, 'profile-age', '22');
    await tap(tester, 'Simpan profil');
    expect(profileSession.value.priorities, ['Protein']);
    await tap(tester, 'Lihat detail');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('profile-name')), findsNothing);
    await tap(tester, 'Perhatikan gula');
    await tap(tester, 'Perhatikan kalori');
    await tap(tester, 'Kosongkan preferensi');
    await tap(tester, 'Simpan personalisasi');
    expect(profileSession.value.name, 'Naya');
    expect(profileSession.value.age, 22);
    expect(profileSession.value.priorities, ['Gula', 'Protein', 'Kalori']);
    expect(profileSession.value.preference, isNull);
    await tap(tester, 'History');
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(
      tester.widget<HistoryScreen>(find.byType(HistoryScreen)).preview,
      isFalse,
    );
    expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    await tap(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Naya'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Naya'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Edit profil'));
    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    await enter(tester, 'profile-name', 'Tidak disimpan');
    await tap(tester, 'Kembali');
    await tap(tester, 'Buang perubahan');
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
      await enter(tester, 'profile-age', '-2');
      await tap(tester, 'Simpan profil');
      expect(saved, isNull);
      expect(find.text('Pilih minimal satu prioritas.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('profile-age')));
      expect(find.text('Isi usia 1–120 tahun atau kosongkan.'), findsOneWidget);
      await enter(tester, 'profile-age', '');
      await tap(tester, 'Nutrisi seimbang');
      await tap(tester, 'Simpan profil');
      expect(saved?.age, isNull);
      expect(saved?.name, '');
      expect(saved?.priorities, ['Keseimbangan']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty history has no filters and scan does not invent records', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HistoryScreen()),
    );
    expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Semua tanggal'), findsNothing);
    await tap(tester, 'Mulai pindai');
    expect(find.text('Kamera makanan belum tersedia.'), findsOneWidget);
    expect(find.byType(HistoryEntryCard), findsNothing);
  });

  testWidgets(
    'complete profile saves decimal measurements, food pattern and allergens',
    (tester) async {
      NutritionProfile? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NutritionProfileScreen(
            profile: NutritionProfile(priorities: ['Gula']),
            onSave: (value) => saved = value,
            onCancel: () {},
          ),
        ),
      );
      await enter(tester, 'profile-height', '165');
      await enter(tester, 'profile-weight', '58,5');
      final pattern = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(pattern);
      await tester.pumpAndSettle();
      await tester.tap(pattern);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vegetarian').last);
      await tester.pumpAndSettle();
      await tap(tester, 'Utamakan makanan halal');
      final allergy = find.byType(DropdownButtonFormField<AllergyStatus>);
      await tester.ensureVisible(allergy);
      await tester.pumpAndSettle();
      await tester.tap(allergy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada bahan yang dihindari').last);
      await tester.pumpAndSettle();
      await tap(tester, 'Kacang tanah');
      await enter(tester, 'other-allergies', 'Wijen');
      await tap(tester, 'Simpan profil');
      expect(saved?.heightCm, 165);
      expect(saved?.weightKg, 58.5);
      expect(saved?.eatingPattern, 'Vegetarian');
      expect(saved?.prefersHalal, isTrue);
      expect(saved?.allergyStatus, AllergyStatus.listed);
      expect(saved?.allergies, ['Kacang tanah']);
      expect(saved?.otherAllergies, 'Wijen');
      final repeatedOnboarding = saved!.withOnboardingChoices('Protein', null);
      expect(repeatedOnboarding.heightCm, 165);
      expect(repeatedOnboarding.allergies, ['Kacang tanah']);
      expect(repeatedOnboarding.priorities, ['Protein']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown allergy differs from none; optional fields clear without invented zero',
    (tester) async {
      NutritionProfile? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NutritionProfileScreen(
            profile: NutritionProfile(
              priorities: ['Gula'],
              heightCm: 165,
              weightKg: 58,
              allergyStatus: AllergyStatus.listed,
              allergies: ['Susu'],
              otherAllergies: 'Wijen',
            ),
            onSave: (value) => saved = value,
            onCancel: () {},
          ),
        ),
      );
      await enter(tester, 'profile-height', '0');
      await tap(tester, 'Simpan profil');
      expect(saved, isNull);
      expect(
        find.text('Isi angka lebih dari 0 sampai 300 cm atau kosongkan.'),
        findsOneWidget,
      );
      await enter(tester, 'profile-height', '');
      await enter(tester, 'profile-weight', '');
      final allergy = find.byType(DropdownButtonFormField<AllergyStatus>);
      await tester.ensureVisible(allergy);
      await tester.pumpAndSettle();
      await tester.tap(allergy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tidak ada yang diketahui').last);
      await tester.pumpAndSettle();
      await tap(tester, 'Simpan profil');
      expect(saved?.heightCm, isNull);
      expect(saved?.weightKg, isNull);
      expect(saved?.allergies, isEmpty);
      expect(saved?.otherAllergies, isEmpty);
      expect(saved?.allergyStatus, AllergyStatus.noneKnown);
      expect(NutritionProfile().allergyStatus, AllergyStatus.unknown);
    },
  );

  testWidgets(
    'listed allergy needs a named ingredient and back offers recovery',
    (tester) async {
      NutritionProfile? saved;
      var cancelled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NutritionProfileScreen(
            profile: NutritionProfile(
              priorities: ['Gula'],
              allergyStatus: AllergyStatus.listed,
            ),
            onSave: (value) => saved = value,
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tap(tester, 'Simpan profil');
      expect(saved, isNull);
      expect(find.text('Pilih bahan atau tulis bahan lain.'), findsOneWidget);
      await enter(tester, 'other-allergies', 'Wijen');
      await tap(tester, 'Batal');
      await tap(tester, 'Lanjut mengedit');
      expect(cancelled, isFalse);
      expect(find.byType(NutritionProfileScreen), findsOneWidget);
      await tap(tester, 'Batal');
      await tap(tester, 'Buang perubahan');
      expect(cancelled, isTrue);
    },
  );

  testWidgets(
    'history preview shows photos and summaries without demo labels or filters',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HistoryScreen(preview: true, now: DateTime(2026, 11, 7)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DATA ILUSTRASI'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Semua tanggal'), findsNothing);
      expect(find.text('Yogurt stroberi'), findsOneWidget);
      expect(find.byType(HistoryPhoto), findsWidgets);
      expect(find.textContaining('Ada 8 g protein'), findsOneWidget);
      await tap(tester, 'Yogurt stroberi');
      expect(find.byType(HistoryEntryDetail), findsOneWidget);
      await tap(tester, 'Tentang data nutrisi');
      expect(find.text('Acuan perhitungan: Per sajian 150 g'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(
        find.text('Ringkasan \u00b7 Yuk, lihat trade-off-nya'),
        findsOneWidget,
      );
      expect(
        find.text('Fokus saat dicatat: Gula \u00b7 Protein'),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byType(HistoryEntryDetail))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(HistoryEntryDetail), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history keeps null distinct from zero and excludes fixtures from real records',
    (tester) async {
      final fixtures = historyPreviewData(DateTime(2026, 11, 7));
      expect(nutrientText(fixtures[1].sugarG, 'g'), 'Belum tersedia');
      expect(nutrientText(fixtures[2].sugarG, 'g'), '0 g');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HistoryScreen(entries: fixtures),
        ),
      );
      expect(find.byType(HistoryEntryCard), findsNothing);
      expect(find.text('Belum ada hasil tersimpan'), findsOneWidget);
    },
  );

  testWidgets(
    'profile summary reveals details and audio preference survives navigation',
    (tester) async {
      profileSession.value = NutritionProfile(
        name: 'Naya',
        priorities: NutritionProfile.priorityOptions,
        heightCm: 165,
      );
      analysisAudioSession.value = false;
      appRouter.go(AppRoutes.profile);
      await tester.pumpWidget(const NutriLensApp());
      await tester.pumpAndSettle();
      expect(find.text('+2 lainnya'), findsNothing);
      for (final priority in NutritionProfile.priorityOptions) {
        expect(find.text(priority), findsOneWidget);
      }
      expect(find.text('Pola makan'), findsOneWidget);
      expect(find.text('Preferensi halal'), findsOneWidget);
      expect(find.text('Alergi makanan'), findsOneWidget);
      expect(find.text('165 cm'), findsNothing);
      await tap(tester, 'Audio analisis');
      expect(analysisAudioSession.value, isTrue);
      await tap(tester, 'History');
      await tap(tester, 'Profile');
      expect(analysisAudioSession.value, isTrue);
      await tap(tester, 'Audio analisis');
      expect(analysisAudioSession.value, isFalse);
      await tap(tester, 'Lihat detail');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('profile-height')), findsNothing);
      expect(find.text('1. Prioritas nutrisi'), findsOneWidget);
      await tap(tester, 'Perhatikan gula');
      await tap(tester, 'Kembali');
      await tap(tester, 'Buang perubahan');
      expect(profileSession.value.priorities, NutritionProfile.priorityOptions);
      expect(profileSession.value.heightCm, 165);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'profile and history share Inter and equal text sizes for equivalent roles',
    (tester) async {
      TextStyle effectiveStyle(String value) {
        final rich = find.descendant(
          of: find.text(value),
          matching: find.byType(RichText),
        );
        return (tester.widget<RichText>(rich.first).text as TextSpan).style!;
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProfileScreen(
            profile: NutritionProfile(name: 'Naya', priorities: ['Gula']),
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = effectiveStyle('Profil kamu');
      final section = effectiveStyle('Personalisasi');
      expect(title.fontFamily, 'Inter');
      expect(title.fontSize, 24);
      expect(section.fontSize, 18);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HistoryScreen(preview: true, now: DateTime(2026, 11, 7)),
        ),
      );
      await tester.pumpAndSettle();
      expect(effectiveStyle('Riwayat').fontSize, title.fontSize);
      expect(
        effectiveStyle('Hari ini \u00b7 7 Nov 2026').fontSize,
        section.fontSize,
      );
      expect(effectiveStyle('Yogurt stroberi').fontSize, 16);
      expect(effectiveStyle('Yogurt stroberi').fontFamily, 'Inter');
      expect(
        effectiveStyle(
          'Ada 8 g protein dan 12 g gula dalam porsi ini. Perhatikan keduanya saat memilih camilan.',
        ).fontSize,
        14,
      );
    },
  );

  testWidgets(
    'identity saves without priorities and inline form reflows with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = ValueNotifier(NutritionProfile());
      addTearDown(profile.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ValueListenableBuilder<NutritionProfile>(
            valueListenable: profile,
            builder: (context, value, _) => ProfileScreen(
              profile: value,
              onSave: (value) => profile.value = value,
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byTooltip('Edit profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit profil'));
      await tester.pumpAndSettle();
      await enter(tester, 'profile-name', 'Naya');
      await enter(tester, 'profile-height', '165');
      await tap(tester, 'Simpan profil');
      expect(profile.value.name, 'Naya');
      expect(profile.value.heightCm, 165);
      expect(profile.value.priorities, isEmpty);
      await tap(tester, 'Lihat detail');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(PersonalPage), findsOneWidget);
      await tap(tester, 'Asupan protein');
      await tap(tester, 'Simpan personalisasi');
      expect(profile.value.priorities, ['Protein']);
      expect(profile.value.name, 'Naya');
      expect(profile.value.heightCm, 165);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history renders a local capture and handles a missing photo', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('nutrilens-photo-test-');
    addTearDown(() {
      // Delete only the dedicated directory created by this test.
      if (folder.parent.path == Directory.systemTemp.path &&
          folder.path.contains('nutrilens-photo-test-')) {
        folder.deleteSync(recursive: true);
      }
    });
    final file = File('${folder.path}/capture.jpg');
    await tester.runAsync(() async {
      final bytes = await rootBundle.load('assets/images/history_yogurt.jpg');
      await file.writeAsBytes(bytes.buffer.asUint8List());
    });
    ScanHistoryEntry record(String path) => ScanHistoryEntry(
      id: 'capture',
      name: 'Makanan',
      savedAt: DateTime(2026, 11, 7),
      packaged: false,
      portion: '1 porsi',
      source: '',
      referenceBasis: '',
      photoPath: path,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryPhoto(entry: record(file.path))),
        ),
      );
      await precacheImage(
        FileImage(file),
        tester.element(find.byType(HistoryPhoto)),
      );
    });
    await tester.pumpAndSettle();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryPhoto(entry: record('${folder.path}/missing.jpg')),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'priority controls can be reached and changed with the keyboard',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NutritionProfileScreen(
            profile: NutritionProfile(),
            onSave: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );
    },
  );

  testWidgets('complete form stays usable with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NutritionProfileScreen(
          profile: NutritionProfile(
            priorities: ['Gula'],
            eatingPattern: 'Vegetarian',
            allergyStatus: AllergyStatus.listed,
            allergies: ['Kacang tanah'],
          ),
          onSave: (_) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await enter(tester, 'profile-weight', '58,5');
    await tap(tester, 'Simpan profil');
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
        onSave: (_) {},
      ),
      NutritionProfileScreen(
        profile: NutritionProfile(),
        onSave: (_) {},
        onCancel: () {},
      ),
      const HistoryScreen(),
      HistoryScreen(preview: true, now: DateTime(2026, 11, 7)),
    ]) {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
