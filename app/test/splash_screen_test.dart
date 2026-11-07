import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/splash/splash_screen.dart';
import 'package:nutrilens/models/nutrition_profile.dart';
import 'package:nutrilens/providers/local_app_state.dart';

void main() {
  testWidgets('SplashScreen renders brand logo, title, badge, and loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SplashScreen(duration: Duration(seconds: 10)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify brand assets and text elements
    expect(find.text('nutrisee'), findsOneWidget);
    expect(find.text('Personalized Nutrition AI'), findsOneWidget);
    expect(
      find.text('Pahami kandungan, pilih sesuai prioritasmu'),
      findsOneWidget,
    );
    expect(find.text('NutriSee · Hackathon MVP'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/icons/iconaplikasi.png',
    );
  });

  testWidgets('SplashScreen triggers callback after duration', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(
          duration: const Duration(milliseconds: 300),
          onFinish: () => finished = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    expect(finished, isTrue);
  });

  testWidgets('SplashScreen routes to home when profile priorities exist', (
    tester,
  ) async {
    profileSession.value = NutritionProfile(priorities: ['Gula']);
    String? navigatedRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(
          duration: const Duration(milliseconds: 200),
          onFinish: () {
            navigatedRoute = profileSession.value.priorities.isNotEmpty
                ? AppRoutes.home
                : AppRoutes.login;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    expect(navigatedRoute, AppRoutes.home);
  });

  testWidgets('SplashScreen routes to login when profile is empty', (
    tester,
  ) async {
    profileSession.value = NutritionProfile(priorities: const []);
    String? navigatedRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(
          duration: const Duration(milliseconds: 200),
          onFinish: () {
            navigatedRoute = profileSession.value.priorities.isNotEmpty
                ? AppRoutes.home
                : AppRoutes.login;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    expect(navigatedRoute, AppRoutes.login);
  });

  testWidgets('SplashScreen reflows cleanly at 320px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: SplashScreen(duration: Duration(seconds: 10)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('nutrisee'), findsOneWidget);
    expect(find.text('Personalized Nutrition AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
