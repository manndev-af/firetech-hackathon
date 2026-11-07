import 'package:flutter/material.dart';

import 'widgets/onboarding_widgets.dart';

class OnboardingPreferenceScreen extends StatelessWidget {
  const OnboardingPreferenceScreen({
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
    super.key,
  });

  static const choices = [
    (
      title: 'Masakan rumahan',
      description: 'Menu harian, lauk pauk, dan hidangan lokal rumahan',
    ),
    (
      title: 'Praktis dan cepat',
      description: 'Pilihan santap ringkas, cepat saji, atau makan di luar',
    ),
    (
      title: 'Lebih banyak nabati',
      description: 'Dominan sayur, buah, olahan kedelai, dan serat sehat',
    ),
  ];
  final String? selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => OnboardingLayout(
    header: OnboardingHeader(step: 2, onBack: onBack),
    content: [
      const Text(
        'Pilih pola\nmakanmu',
        style: onboardingTitleStyle,
      ),
      const SizedBox(height: 12),
      const Text(
        'Opsional. Sesuaikan dengan kebiasaan santapmu sehari-hari.',
        style: onboardingBodyStyle,
      ),
      const SizedBox(height: 36),
      for (final choice in choices)
        OnboardingChoice(
          title: choice.title,
          description: choice.description,
          selected: selected == choice.title,
          showUnselectedIcon: false,
          onTap: () => onChanged(choice.title),
        ),
    ],
    footer: [
      OnboardingButton(label: 'Lanjutkan', onPressed: onNext),
      const SizedBox(height: 8),
      TextButton(onPressed: onSkip, child: const Text('Lewati dulu')),
    ],
  );
}
