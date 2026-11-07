import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrilens/features/auth/login_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_screen.dart';
import 'package:nutrilens/features/dashboard/dashboard_screen.dart';
import 'package:nutrilens/shared/layouts/main_scaffold.dart';

import 'route_paths.dart';
import '../../models/nutrition_profile.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/nutrition_profile_screen.dart';
import '../../features/history/history_screen.dart';

// In-memory UI state only; no account, disk storage, or nutrition-engine input.
final profileSession = ValueNotifier<NutritionProfile>(NutritionProfile());

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRouteNames.onboarding,
      builder: (context, state) => OnboardingScreen(
        onComplete: (focus, preference) {
          final current = profileSession.value;
          profileSession.value = NutritionProfile(
            name: current.name,
            age: current.age,
            priorities: [focus],
            preference: preference,
          );
        },
      ),
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
                return ValueListenableBuilder<NutritionProfile>(
                  valueListenable: profileSession,
                  builder: (context, profile, _) => DashboardScreen(
                    focus: profile.priorities.isNotEmpty
                        ? profile.priorities.join(' · ')
                        : focus is String && focuses.contains(focus)
                        ? focus
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              name: AppRouteNames.history,
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: AppRouteNames.profile,
              builder: (context, state) =>
                  ValueListenableBuilder<NutritionProfile>(
                    valueListenable: profileSession,
                    builder: (context, profile, _) => ProfileScreen(
                      profile: profile,
                      onEdit: () => context.push(AppRoutes.nutritionProfile),
                    ),
                  ),
              routes: [
                GoRoute(
                  path: 'nutrition',
                  name: AppRouteNames.nutritionProfile,
                  builder: (context, state) => NutritionProfileScreen(
                    profile: profileSession.value,
                    onCancel: () => context.pop(),
                    onSave: (profile) {
                      profileSession.value = profile;
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil disimpan untuk sesi ini.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
    //   path: AppRoutes.insight,
    //   name: AppRouteNames.insight,
    //   builder: (context, state) => const RoutePlaceholderScreen(
    //     title: 'Personalized Insight',
    //     description: 'Trade-off berdasarkan prioritas nutrisi pengguna.',
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
