import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/features/explore/compare_screen.dart';

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

    await tester.tap(find.text('Pilihan B'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

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
    expect(find.text('Selesai'), findsOneWidget);
  });
}
