import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/daily_nutrition_summary.dart';
import '../../models/scan_history_entry.dart';
import '../../providers/local_app_state.dart';
import '../../shared/widgets/navigation/top_nav.dart';
import '../history/widgets/history_entry_card.dart';
import 'widgets/dashboard_history.dart';
import 'widgets/dashboard_scan_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    this.summary,
    this.focus,
    this.recentEntry,
    this.onScan,
    this.onExplore,
    this.onViewHistory,
    this.now,
    super.key,
  });

  final DailyNutritionSummary? summary;
  final String? focus;
  final ScanHistoryEntry? recentEntry;
  final VoidCallback? onScan;
  final VoidCallback? onExplore;
  final VoidCallback? onViewHistory;
  final DateTime? now;

  void _unavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    final hour = (now ?? DateTime.now()).hour;
    final greeting = hour < 11
        ? 'SELAMAT PAGI'
        : hour < 15
        ? 'SELAMAT SIANG'
        : hour < 18
        ? 'SELAMAT SORE'
        : 'SELAMAT MALAM';
    final scan = onScan ?? () => _unavailable(context, 'Kamera makanan');
    final explore = onExplore ?? () => _unavailable(context, 'Jelajahi');
    final viewHistory = onViewHistory ?? explore;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const TopNav(showLogo: true),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Makan dengan\nlebih paham.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DashboardScanCard(focus: focus, onScan: scan),
                  if (recentEntry != null) ...[
                    const SizedBox(height: 28),
                    _RecentAnalysisCard(
                      entry: recentEntry!,
                      onViewHistory: viewHistory,
                    ),
                  ],
                  const SizedBox(height: 28),
                  DashboardHistory(
                    summary: summary,
                    onScan: scan,
                    onExplore: explore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentAnalysisCard extends StatelessWidget {
  const _RecentAnalysisCard({
    required this.entry,
    this.onViewHistory,
  });

  final ScanHistoryEntry entry;
  final VoidCallback? onViewHistory;

  Widget _buildPhoto() {
    String? photoPath = entry.photoPath;
    if ((photoPath == null || photoPath.isEmpty || !File(photoPath).existsSync()) && localStorage != null) {
      final diskFile = File('${localStorage!.directory.path}/photos/${entry.id}.jpg');
      if (diskFile.existsSync()) {
        photoPath = diskFile.path;
      }
    }
    if (photoPath != null && File(photoPath).existsSync()) {
      return Image.file(
        File(photoPath),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackPhoto(),
      );
    }
    final isYogurtSample = entry.id == 'sample_history_yogurt' ||
        entry.id == 'preview-yogurt' ||
        entry.name.toLowerCase().contains('yogurt');
    final effectiveAsset = entry.photoAsset ??
        (isYogurtSample ? 'assets/images/history_yogurt.jpg' : null);

    if (effectiveAsset != null) {
      return Image.asset(
        effectiveAsset,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackPhoto(),
      );
    }
    return _fallbackPhoto();
  }

  Widget _fallbackPhoto() => Container(
    width: 64,
    height: 64,
    color: AppColors.mint,
    alignment: Alignment.center,
    child: const Icon(
      Icons.restaurant_rounded,
      color: AppColors.primary,
      size: 28,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Analisis Terakhir',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onViewHistory != null)
              GestureDetector(
                onTap: onViewHistory,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat semua riwayat',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onViewHistory,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildPhoto(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.portion} · ${historyDate(entry.savedAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (entry.prioritySnapshot.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  entry.prioritySnapshot.join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.note,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _badge('Protein', nutrientText(entry.proteinG, 'g')),
                      _badge('Gula', nutrientText(entry.sugarG, 'g')),
                      _badge('Energi', nutrientText(entry.energyKcal, 'kkal')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
    ),
    child: Text(
      '$label $value',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
