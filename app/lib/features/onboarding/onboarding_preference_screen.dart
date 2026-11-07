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
      description: 'Nasi, lauk, sayur, dan rasa yang familier',
    ),
    (
      title: 'Praktis dan cepat',
      description: 'Pilihan mudah di sela aktivitas',
    ),
    (title: 'Lebih banyak nabati', description: 'Sayur, buah, tahu, dan tempe'),
  ];
  final String? selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => OnboardingLayout(
    content: [
      OnboardingHeader(step: 2, onBack: onBack),
      const SizedBox(height: 16),
      const Text(
        'Makanan seperti apa\nyang kamu suka?',
        style: onboardingTitleStyle,
      ),
      const SizedBox(height: 12),
      const Text(
        'Opsional. Pilih yang paling dekat denganmu.',
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
