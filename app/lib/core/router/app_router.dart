import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrilens/features/auth/login_screen.dart';
import 'package:nutrilens/features/onboarding/onboarding_screen.dart';
import 'package:nutrilens/features/dashboard/dashboard_screen.dart';
import 'package:nutrilens/shared/layouts/main_scaffold.dart';

import 'route_paths.dart';
import '../../models/daily_nutrition_summary.dart';
import '../../models/history_preview_data.dart';
import '../../models/nutrition_profile.dart';
import '../../models/scan_history_entry.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/nutrition_profile_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/explore/compare_screen.dart';
import '../../features/explore/assistant_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/scanner/scan_result_screen.dart';
import '../../providers/local_app_state.dart';
import '../../services/scan_pipeline.dart';
export '../../providers/local_app_state.dart'
    show profileSession, analysisAudioSession;

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRouteNames.onboarding,
      builder: (context, state) => OnboardingScreen(
        onComplete: (focus, preference) {
          final current = profileSession.value;
          profileSession.value = current.withOnboardingChoices(
            focus,
            preference,
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
                  builder: (context, profile, _) =>
                      ValueListenableBuilder<List<ScanHistoryEntry>>(
                    valueListenable: historySession,
                    builder: (context, history, _) {
                      final hasRealHistory = history.isNotEmpty;
                      final isPreview =
                          const bool.fromEnvironment('UI_PREVIEW') &&
                          !hasRealHistory;
                      final entries = hasRealHistory
                          ? history
                          : (isPreview
                              ? historyPreviewData(DateTime.now())
                              : <ScanHistoryEntry>[]);
                      final recent = entries.isNotEmpty ? entries.first : null;

                      DailyNutritionSummary? summary;
                      if (entries.isNotEmpty) {
                        final now = DateTime.now();
                        final todayEntries = entries
                            .where((e) =>
                                DateUtils.isSameDay(e.savedAt, now) ||
                                isPreview)
                            .toList();
                        if (todayEntries.isNotEmpty) {
                          var sugarCount = 0;
                          var proteinCount = 0;
                          var energyCount = 0;
                          double totalSugar = 0;
                          double totalProtein = 0;
                          double totalEnergy = 0;
                          for (final e in todayEntries) {
                            if (e.sugarG != null) {
                              sugarCount++;
                              totalSugar += e.sugarG!;
                            }
                            if (e.proteinG != null) {
                              proteinCount++;
                              totalProtein += e.proteinG!;
                            }
                            if (e.energyKcal != null) {
                              energyCount++;
                              totalEnergy += e.energyKcal!;
                            }
                          }
                          summary = DailyNutritionSummary(
                            recordCount: todayEntries.length,
                            sugarG: sugarCount > 0 ? totalSugar : null,
                            sugarComplete: sugarCount == todayEntries.length,
                            proteinG: proteinCount > 0 ? totalProtein : null,
                            proteinComplete: proteinCount == todayEntries.length,
                            energyKcal: energyCount > 0 ? totalEnergy : null,
                            energyComplete: energyCount == todayEntries.length,
                          );
                        }
                      }

                      return DashboardScreen(
                        onScan: () => context.push(AppRoutes.scanner),
                        onExplore: () => context.go(AppRoutes.explore),
                        onViewHistory: () => context.go(AppRoutes.history),
                        recentEntry: recent,
                        summary: summary,
                        focus: profile.priorities.isNotEmpty
                            ? profile.priorities.join(' · ')
                            : focus is String && focuses.contains(focus)
                            ? focus
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.explore,
              name: AppRouteNames.explore,
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              name: AppRouteNames.history,
              builder: (context, state) => ValueListenableBuilder(
                valueListenable: historySession,
                builder: (context, records, _) => ValueListenableBuilder(
                  valueListenable: draftSession,
                  builder: (context, drafts, _) => HistoryScreen(
                    drafts: drafts,
                    onResume: (draft) =>
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ScanResultScreen(
                              photo: XFile(draft.photoPath),
                              mode: draft.label
                                  ? ScanMode.label
                                  : ScanMode.food,
                              draft: draft,
                            ),
                          ),
                        ),
                    entries: records,
                    onScan: () => context.push(AppRoutes.scanner),
                    // The current design-review build opens populated history.
                    // Fixtures remain separate from actual saved records.
                    preview:
                        const bool.fromEnvironment('UI_PREVIEW') &&
                        records.isEmpty &&
                        drafts.isEmpty,
                  ),
                ),
              ),
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
                      audioPreference: analysisAudioSession,
                      onSave: (value) => profileSession.value = value,
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
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.scanner,
      name: AppRouteNames.scanner,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ScannerScreen(
        onUsePhoto: (photo, mode) async {
          final storage = localStorage;
          if (storage != null) {
            final pipeline = ScanPipeline(storage: storage);
            final draft = await pipeline.prepare(
              photo.path,
              label: mode == ScanMode.label,
              priorities: profileSession.value.priorities,
            );
            await saveDraft(draft);
            if (!context.mounted) return;
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ScanResultScreen(
                  photo: photo,
                  mode: mode,
                  draft: draft,
                ),
              ),
            );
            return;
          }
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ScanResultScreen(photo: photo, mode: mode),
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.comparison,
      name: AppRouteNames.comparison,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CompareScreen(),
    ),
    GoRoute(
      path: AppRoutes.assistant,
      name: AppRouteNames.assistant,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final showConversation = extra == true || extra is String;
        final mode = extra is String
            ? extra
            : (extra == true ? 'pattern' : 'general');
        return AssistantScreen(
          showConversation: showConversation,
          initialMode: mode,
        );
      },
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
