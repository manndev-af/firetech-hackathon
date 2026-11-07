import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/local_app_state.dart';
import '../../shared/widgets/navigation/top_nav.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const TopNav(showLogo: true),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              children: [
                const Text(
                  'Pilihan berikutnya,\nlebih sesuai kamu.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Teman memahami makanan sehari-hari.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                ValueListenableBuilder(
                  valueListenable: profileSession,
                  builder: (context, profile, _) {
                    final focus = profile.priorities.isNotEmpty
                        ? profile.priorities.first
                        : 'gula';
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: AppColors.heroBackground,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fokus ${focus.toLowerCase()} · dari catatanmu',
                                  style: const TextStyle(
                                    color: AppColors.heroBackground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gunakan catatan makan untuk memberi konteks pada percakapan.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Mau bahas apa?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ExploreTile(
                  title: 'Bandingkan dua pilihan',
                  subtitle: 'Lihat porsi, gula, protein, dan trade-off',
                  tag: 'Kamera & Galeri · Trade-Off',
                  icon: Icons.compare_arrows_rounded,
                  onTap: () => context.push(AppRoutes.comparison),
                ),
                const SizedBox(height: 14),
                _ExploreTile(
                  title: 'Lihat pola catatanku',
                  subtitle: 'Pahami makanan yang sering kamu catat',
                  tag: 'Analisis AI Kebiasaan Makan',
                  icon: Icons.insights_rounded,
                  onTap: () => context.push(AppRoutes.assistant, extra: true),
                ),
                const SizedBox(height: 14),
                _ExploreTile(
                  title: 'Tanya soal makanan',
                  subtitle: 'Mulai dari yang sedang kamu pertimbangkan',
                  tag: 'Konsultasi Nutrisi AI',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => context.push(AppRoutes.assistant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.heroBackground,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
