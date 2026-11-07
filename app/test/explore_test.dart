import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/explore/assistant_screen.dart';
import 'package:nutrilens/features/explore/compare_screen.dart';
import 'package:nutrilens/features/explore/explore_screen.dart';
import 'package:nutrilens/shared/widgets/navigation/top_nav.dart';

void main() {
  testWidgets('ExploreScreen renders TopNav and 3 primary action cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TopNav), findsOneWidget);
    expect(find.text('nutrisee'), findsOneWidget);
    expect(find.text('Pilihan berikutnya,\nlebih sesuai kamu.'), findsOneWidget);
    expect(find.text('Mau bahas apa?'), findsOneWidget);
    expect(find.text('Bandingkan dua pilihan'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lihat pola catatanku'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lihat pola catatanku'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tanya soal makanan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tanya soal makanan'), findsOneWidget);
  });

  testWidgets('Tapping Tanya soal makanan opens AI assistant roomchat directly', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: AppRoutes.assistant,
          builder: (context, state) {
            final extra = state.extra;
            final showConversation = extra != false;
            final mode = extra is String ? extra : 'general';
            return AssistantScreen(
              showConversation: showConversation,
              initialMode: mode,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tanya soal makanan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tanya soal makanan'));
    await tester.pumpAndSettle();

    expect(find.byType(AssistantScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Konsultasi nutrisi · online'), findsOneWidget);
    expect(
      find.textContaining('Halo! Saya asisten nutrisi NutriSee'),
      findsOneWidget,
    );
  });

  testWidgets('CompareScreen presents camera/gallery option and supports summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CompareScreen(pickImage: () async => '/test/food.jpg'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih dua\ngambar makanan.'), findsOneWidget);
    await tester.tap(find.text('Pilihan A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilihan B'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lihat ringkasan'));
    await tester.pumpAndSettle();

    expect(find.text('Dua pilihan,\nbasis yang sama.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lebih sedikit gula,\nprotein juga berbeda.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Lebih sedikit gula,\nprotein juga berbeda.'),
      findsOneWidget,
    );
    expect(find.text('Bahas pilihan ini'), findsNothing);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('AssistantScreen in compare mode displays comparison analysis and responds to chats', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AssistantScreen(
          showConversation: true,
          initialMode: 'compare',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asisten nutrisi'), findsOneWidget);
    expect(find.text('Perbandingan dua pilihan · trade-off AI'), findsOneWidget);
    expect(
      find.textContaining('Bantu aku membandingkan Pilihan A dan Pilihan B'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Pilihan B memotong gula hingga 50%'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);

    // Tap prompt chip
    await tester.scrollUntilVisible(
      find.text('Mending mana untuk sarapan?'),
      50,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mending mana untuk sarapan?'));
    await tester.pump();

    // Wait for AI reply
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Personalized Nutrition Trade-Off'), findsOneWidget);

    // Verify fixed back button remains visible and hit-testable even after scrolling
    expect(find.byTooltip('Kembali').hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back).hitTestable(), findsOneWidget);
  });

  testWidgets('AssistantScreen in pattern mode loads consumption pattern analysis', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AssistantScreen(
          showConversation: true,
          initialMode: 'pattern',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fokus gula · pola dari catatanmu'), findsOneWidget);
    expect(find.text('Konteks: catatan hari ini · data contoh'), findsOneWidget);
    expect(
      find.text(
        'Lihat pola makanan yang sering aku catat.\nBagaimana tren gula?',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Makanan apa yang sering tercatat?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Makanan apa yang sering tercatat?'), findsOneWidget);

    // Tap prompt chip to trigger AI reply
    await tester.tap(find.text('Makanan apa yang sering tercatat?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('sebagian besar kalori berasal'), findsOneWidget);
  });

  testWidgets('AssistantScreen in general mode starts with landing and activates conversation on prompt tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AssistantScreen(showConversation: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih makanan yang ingin kamu pahami'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Tap quick prompt to start conversation
    await tester.tap(find.text('Tips memilih camilan sehat'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tips memilih camilan sehat'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Memilih camilan sehat:'), findsOneWidget);
  });
}
