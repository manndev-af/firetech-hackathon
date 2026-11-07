import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/daily_nutrition_summary.dart';
import 'widgets/dashboard_history.dart';
import 'widgets/dashboard_scan_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    this.summary,
    this.focus,
    this.onScan,
    this.onExplore,
    this.now,
    super.key,
  });

  final DailyNutritionSummary? summary;
  final String? focus;
  final VoidCallback? onScan;
  final VoidCallback? onExplore;
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Makan dengan\nlebih paham.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DashboardScanCard(focus: focus, onScan: scan),
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
