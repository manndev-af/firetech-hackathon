import 'package:go_router/go_router.dart';
import 'package:nutrilens/features/auth/login_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_screen.dart';
import 'package:nutrilens/features/dashboard/dashboard_screen.dart';
import 'package:nutrilens/shared/layouts/main_scaffold.dart';

import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: AppRouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) {
                const focuses = {'Gula', 'Protein', 'Natrium', 'Keseimbangan'};
                final focus = state.extra;
                return DashboardScreen(
                  focus: focus is String && focuses.contains(focus)
                      ? focus
                      : null,
                );
              },
            ),
          ],
        ),
      ],
    ),
    // GoRoute(
    //   path: AppRoutes.splash,
    //   name: AppRouteNames.splash,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Splash',
    //     description: 'Titik masuk NutriLens AI.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.onboarding,
    //   name: AppRouteNames.onboarding,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Onboarding personalisasi',
    //     description: 'Pengaturan preferensi dan prioritas nutrisi.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.home,
    //   name: AppRouteNames.home,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Home',
    //     description: 'Beranda dan akses utama untuk memindai makanan.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.scanner,
    //   name: AppRouteNames.scanner,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Food Scanner',
    //     description: 'Pilih jalur makanan kemasan atau tanpa kemasan.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.recognition,
    //   name: AppRouteNames.recognition,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Food Recognition',
    //     description: 'Tinjau kandidat klasifikasi dan confidence model.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.portionConfirmation,
    //   name: AppRouteNames.portionConfirmation,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Konfirmasi porsi',
    //     description: 'Konfirmasi jenis makanan, jumlah, dan satuannya.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.nutritionResult,
    //   name: AppRouteNames.nutritionResult,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Hasil nutrisi',
    //     description: 'Nilai nutrisi beserta sumber dan basis sajiannya.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.explore,
    //   name: AppRouteNames.explore,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Jelajahi',
    //     description: 'Jelajahi informasi nutrisi dan perbandingan makanan.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.comparison,
    //   name: AppRouteNames.comparison,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Food Comparison',
    //     description: 'Bandingkan makanan pada basis sajian yang setara.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.history,
    //   name: AppRouteNames.history,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'History',
    //     description: 'Riwayat analisis yang tersimpan.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.nutritionProfile,
    //   name: AppRouteNames.nutritionProfile,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Nutrition Profile',
    //     description: 'Preferensi makanan dan prioritas nutrisi.',
    //   ),
    // ),
    // GoRoute(
    //   path: AppRoutes.profile,
    //   name: AppRouteNames.profile,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Profile & Settings',
    //     description: 'Profil dan pengaturan aplikasi.',
    //   ),
    // ),
  ],
);
