import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/app.dart';
import 'package:nutrilens/core/router/app_router.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/auth/login_screen.dart';
import 'package:nutrilens/shared/layouts/main_scaffold.dart';

void main() {
  testWidgets('offers only Google login and renders the bundled illustration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kenali isi piringmu.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Daftar'), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/login_reference.png',
    );
    expect(find.text('Prototipe · login belum terhubung'), findsOneWidget);
    final button = find.text('Lanjutkan dengan Google');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.text('Login Google belum terhubung. Akun belum masuk.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login route remains outside the navigation shell', (
    tester,
  ) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const NutriLensApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScaffold), findsNothing);
    expect(appRouter.namedLocation(AppRouteNames.login), AppRoutes.login);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
  });

  testWidgets(
    'Google login remains usable on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Lanjutkan dengan Google');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text('Login Google belum terhubung. Akun belum masuk.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text('Prototipe · login belum terhubung'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
