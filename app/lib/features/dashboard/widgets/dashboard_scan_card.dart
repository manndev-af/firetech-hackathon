import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class DashboardScanCard extends StatelessWidget {
  const DashboardScanCard({required this.onScan, this.focus, super.key});
  final VoidCallback onScan;
  final String? focus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.heroBackground,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.heroBackground.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'FOKUSMU · ${focus?.toUpperCase() ?? 'BELUM DIPILIH'}',
            style: const TextStyle(
              color: AppColors.mint,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const titleWidget = Text(
              'Apa isi\npiringmu?',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 28,
                height: 1.25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            );

            final imageWidget = Semantics(
              image: true,
              label: 'Ilustrasi semangkuk makanan',
              child: SvgPicture.asset(
                'assets/images/foodartwork.svg',
                height: 110,
                fit: BoxFit.contain,
              ),
            );

            if (constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 12),
                  SizedBox(width: 140, child: imageWidget),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: titleWidget),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 105,
                  child: imageWidget,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'Foto makanan atau label gizinya untuk memahami isi dan porsinya.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onScan,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.mint,
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(172, 48),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Foto makanan',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
