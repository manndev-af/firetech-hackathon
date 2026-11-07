import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/history/history_screen.dart';
import 'package:nutrilens/features/profile/profile_screen.dart';
import 'package:nutrilens/features/profile/nutrition_profile_screen.dart';
import 'package:nutrilens/models/nutrition_profile.dart';
import 'package:nutrilens/shared/widgets/navigation/bottom_nav.dart';

// Opt-in PNG exports from real Flutter widgets, not marketing mockups.
void main() {
  testWidgets('export profile and history review screens', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_UI_PREVIEWS')) return;
    final fonts = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final screens = <String, Widget>{
      'profile': ProfileScreen(
        profile: NutritionProfile(
          name: 'Naya',
          age: 22,
          priorities: ['Gula', 'Protein'],
          preference: 'Masakan rumahan',
          heightCm: 165,
          weightKg: 58.5,
          eatingPattern: 'Fleksibel',
          prefersHalal: true,
          allergyStatus: AllergyStatus.listed,
          allergies: ['Kacang tanah'],
        ),
        onSave: (_) {},
      ),
      'profile-inline': ProfileScreen(
        profile: NutritionProfile(
          name: 'Naya',
          age: 22,
          priorities: ['Gula', 'Protein'],
        ),
        onSave: (_) {},
      ),
      'profile-identity': ProfileScreen(
        profile: NutritionProfile(
          name: 'Naya',
          age: 22,
          priorities: ['Gula', 'Protein'],
        ),
        onSave: (_) {},
      ),
      'history-empty': const HistoryScreen(),
      'history-filled': HistoryScreen(
        preview: true,
        now: DateTime(2026, 11, 7),
      ),
      'profile-editor': NutritionProfileScreen(
        profile: NutritionProfile(priorities: ['Gula', 'Protein']),
        onSave: (_) {},
        onCancel: () {},
      ),
      'profile-editor-allergies': NutritionProfileScreen(
        profile: NutritionProfile(
          priorities: ['Gula', 'Protein'],
          allergyStatus: AllergyStatus.listed,
          allergies: ['Kacang tanah'],
        ),
        onSave: (_) {},
        onCancel: () {},
      ),
      'history-detail': HistoryScreen(
        preview: true,
        now: DateTime(2026, 11, 7),
      ),
    };
    for (final entry in screens.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              extendBody: true,
              body: entry.value,
              bottomNavigationBar: BottomNav(
                currentIndex: entry.key.startsWith('profile') ? 3 : 2,
                onTap: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final name in ['yogurt', 'rice', 'tea']) {
          await precacheImage(
            AssetImage('assets/images/history_$name.jpg'),
            tester.element(find.byType(Scaffold).first),
          );
        }
      });
      await tester.pumpAndSettle();
      if (entry.key == 'profile-inline') {
        await tester.ensureVisible(find.text('Lihat detail'));
        await tester.tap(find.text('Lihat detail'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('1. Prioritas nutrisi'));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'profile-identity') {
        await tester.tap(find.byTooltip('Edit profil'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Informasi profil'));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'profile-editor-allergies') {
        await tester.ensureVisible(find.text('3. Alergi makanan'));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'history-detail') {
        await tester.ensureVisible(find.text('Yogurt stroberi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yogurt stroberi'));
        await tester.pumpAndSettle();
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        const folder = String.fromEnvironment(
          'PREVIEW_FOLDER',
          defaultValue: 'after',
        );
        final file = File('build/ui-audit/$folder/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
