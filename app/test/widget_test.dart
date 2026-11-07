import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/app.dart';
import 'package:nutrilens/core/router/app_router.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/features/auth/login_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_focus_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_preference_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_finish_screen.dart';
import 'package:nutrilens/features/onboarding/widgets/onboarding_widgets.dart';
import 'package:nutrilens/shared/layouts/main_scaffold.dart';

void main() {
  Future<void> start(WidgetTester tester) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const NutriLensApp());
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Google prototype opens onboarding without an authenticated session',
    (tester) async {
      await start(tester);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Daftar'), findsNothing);
      expect(find.text('Prototipe · login belum terhubung'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/login_reference.png',
      );
      await tap(tester, 'Lanjutkan dengan Google');
      expect(find.byType(OnboardingFocusScreen), findsOneWidget);
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding,
      );
      expect(find.byType(MainScaffold), findsNothing);
      expect(
        appRouter.namedLocation(AppRouteNames.onboarding),
        AppRoutes.onboarding,
      );
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'focus and preference selections survive back and appear on finish',
    (tester) async {
      await start(tester);
      await tap(tester, 'Lanjutkan dengan Google');
      await tap(tester, 'Protein');
      await tap(tester, 'Lanjutkan');
      expect(find.byType(OnboardingPreferenceScreen), findsOneWidget);
      await tap(tester, 'Lebih banyak nabati');
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OnboardingFocusScreen>(find.byType(OnboardingFocusScreen))
            .selected,
        'Protein',
      );
      await tap(tester, 'Lanjutkan');
      expect(
        tester
            .widget<OnboardingPreferenceScreen>(
              find.byType(OnboardingPreferenceScreen),
            )
            .selected,
        'Lebih banyak nabati',
      );
      await tap(tester, 'Lanjutkan');
      expect(find.byType(OnboardingFinishScreen), findsOneWidget);
      expect(
        find.text(
          'Fokus protein sudah dipilih. Catat makanan pertamamu untuk melihat rangkumannya.',
        ),
        findsOneWidget,
      );
      expect(find.text('Preferensi: Lebih banyak nabati'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPreferenceScreen), findsOneWidget);
      await tap(tester, 'Lanjutkan');
      await tap(tester, 'Ke beranda');
      expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.home);
      expect(find.byType(MainScaffold), findsOneWidget);
    },
  );

  testWidgets('skipping clears the optional preference', (tester) async {
    await start(tester);
    await tap(tester, 'Lanjutkan dengan Google');
    await tap(tester, 'Natrium');
    await tap(tester, 'Lanjutkan');
    await tap(tester, 'Praktis dan cepat');
    await tap(tester, 'Lewati dulu');
    final finish = tester.widget<OnboardingFinishScreen>(
      find.byType(OnboardingFinishScreen),
    );
    expect(finish.focus, 'Natrium');
    expect(finish.preference, isNull);
    expect(find.textContaining('Preferensi:'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OnboardingPreferenceScreen>(
            find.byType(OnboardingPreferenceScreen),
          )
          .selected,
      isNull,
    );
  });

  testWidgets(
    'onboarding supports narrow screens, large text and accessible selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      await start(tester);
      await tap(tester, 'Lanjutkan dengan Google');
      await tap(tester, 'Keseimbangan');
      final choice = find.byWidgetPredicate(
        (widget) =>
            widget is OnboardingChoice && widget.title == 'Keseimbangan',
      );
      expect(tester.widget<OnboardingChoice>(choice).selected, isTrue);
      await tap(tester, 'Lanjutkan');
      await tap(tester, 'Lewati dulu');
      await tester.ensureVisible(find.text('Ke beranda'));
      expect(find.byType(OnboardingFinishScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
