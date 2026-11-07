import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/daily_nutrition_summary.dart';

class DashboardHistory extends StatelessWidget {
  const DashboardHistory({
    required this.onScan,
    required this.onExplore,
    this.summary,
    super.key,
  });
  final DailyNutritionSummary? summary;
  final VoidCallback onScan;
  final VoidCallback onExplore;

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final data = summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            const Text(
              'Hari ini',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              data == null
                  ? 'Belum ada catatan'
                  : '${data.recordCount} catatan',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (data == null) ...[
          const Text(
            'Mulai dengan satu makanan.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rangkumanmu muncul setelah kamu\nmengonfirmasi dan mencatat makanan.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: onScan,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Catat makanan pertama',
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth >= 280 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 20;
                final width = compact
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 20,
                  children: [
                    _metric(width, data.sugarG, 'g', 'Gula tercatat'),
                    _metric(width, data.proteinG, 'g', 'Protein'),
                    _metric(width, data.energyKcal, 'kkal', 'Energi'),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.incompleteNutrients.isEmpty
                ? 'Catatan hari ini · berdasarkan makanan yang dicatat.'
                : 'Catatan hari ini · data ${data.incompleteNutrients.join(', ')} belum lengkap.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onExplore,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mau bandingkan minuman berikutnya?',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Buka Jelajah  →',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric(double width, double? value, String unit, String label) =>
      SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value == null ? 'Belum tersedia' : '${_format(value)} $unit',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
