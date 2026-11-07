import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DashboardScanCard extends StatelessWidget {
  const DashboardScanCard({required this.onScan, this.focus, super.key});
  final VoidCallback onScan;
  final String? focus;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.heroBackground,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOKUSMU · ${focus?.toUpperCase() ?? 'BELUM DIPILIH'}',
          style: const TextStyle(color: AppColors.surface, fontSize: 12),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final image = Semantics(
              image: true,
              label: 'Ilustrasi semangkuk makanan',
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 162 / 128,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, imageConstraints) {
                        final scale = imageConstraints.maxWidth / 162;
                        return Stack(
                          children: [
                            Positioned(
                              left: -184 * scale,
                              top: -230 * scale,
                              width: 390 * scale,
                              height: 844 * scale,
                              child: Image.asset(
                                'assets/images/dashboard_reference.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
            const title = Text(
              'Apa isi\npiringmu?',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 28,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            );
            if (constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 12),
                  SizedBox(width: 180, child: image),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: title),
                Expanded(child: image),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onScan,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.mint,
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(172, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text('Foto makanan', textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}
