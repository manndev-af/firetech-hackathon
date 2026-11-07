import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingFinishScreen extends StatelessWidget {
  const OnboardingFinishScreen({
    required this.focus,
    required this.preference,
    required this.onHome,
    super.key,
  });
  final String focus;
  final String? preference;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => OnboardingLayout(
    bottomSpace: 60,
    content: [
      const SizedBox(height: 64),
      Semantics(
        image: true,
        label: 'Ilustrasi semangkuk nasi, ayam, telur, dan sayuran',
        child: ExcludeSemantics(
          child: AspectRatio(
            aspectRatio: 342 / 270,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / 342;
                  // Render only the illustration from the supplied full-screen export.
                  return Stack(
                    children: [
                      Positioned(
                        left: -24 * scale,
                        top: -100 * scale,
                        width: 390 * scale,
                        height: 844 * scale,
                        child: Image.asset(
                          'assets/images/onboarding_finish_reference.png',
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
      ),
      const SizedBox(height: 24),
      const Text(
        'MULAI DARI YANG KAMU MAKAN',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Sedikit lebih paham,\nsetiap kali makan.',
        style: onboardingTitleStyle,
      ),
      const SizedBox(height: 20),
      Text(
        'Fokus ${focus.toLowerCase()} sudah dipilih. Catat makanan pertamamu untuk melihat rangkumannya.',
        style: onboardingBodyStyle.copyWith(fontSize: 16),
      ),
      if (preference != null) ...[
        const SizedBox(height: 12),
        Text('Preferensi: $preference', style: onboardingBodyStyle),
      ],
    ],
    footer: [OnboardingButton(label: 'Ke beranda', onPressed: onHome)],
  );
}
