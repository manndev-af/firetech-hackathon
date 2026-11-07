import 'package:flutter/material.dart';

import 'widgets/onboarding_widgets.dart';

class OnboardingFocusScreen extends StatelessWidget {
  const OnboardingFocusScreen({
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  static const choices = [
    (title: 'Gula', description: 'Pantau dan batasi konsumsi gula harian'),
    (title: 'Protein', description: 'Cukupi asupan protein untuk energi & otot'),
    (title: 'Natrium', description: 'Kendalikan kadar garam untuk kesehatan sirkulasi'),
    (title: 'Keseimbangan', description: 'Pantau proporsi kalori dan nutrisi secara seimbang'),
  ];
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => OnboardingLayout(
    header: OnboardingHeader(step: 1, onBack: onBack),
    bottomSpace: 96,
    content: [
      const Text(
        'Pilih fokus\nnutrisimu',
        style: onboardingTitleStyle,
      ),
      const SizedBox(height: 12),
      const Text(
        'Tentukan prioritas untuk memandu analisis makanan harianmu.',
        style: onboardingBodyStyle,
      ),
      const SizedBox(height: 36),
      for (final choice in choices)
        OnboardingChoice(
          title: choice.title,
          description: choice.description,
          selected: selected == choice.title,
          onTap: () => onChanged(choice.title),
        ),
    ],
    footer: [OnboardingButton(label: 'Lanjutkan', onPressed: onNext)],
  );
}
