import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/app.dart';

void main() {
  testWidgets('starts on Splash and navigates to Home', (tester) async {
    await tester.pumpWidget(const NutriLensApp());
    await tester.pumpAndSettle();

    expect(find.text('Splash'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(find.text('Beranda dan akses utama untuk memindai makanan.'),
        findsOneWidget);
  });
}
