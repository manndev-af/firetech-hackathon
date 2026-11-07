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
    (title: 'Gula', description: 'Memahami gula dalam makananmu'),
    (title: 'Protein', description: 'Melihat sumber protein dalam makananmu'),
    (title: 'Natrium', description: 'Memperhatikan kandungan garam'),
    (title: 'Keseimbangan', description: 'Memahami beberapa nutrisi bersama'),
  ];
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => OnboardingLayout(
    bottomSpace: 96,
    content: [
      OnboardingHeader(step: 1, onBack: onBack),
      const SizedBox(height: 16),
      const Text(
        'Apa yang ingin\nkamu perhatikan?',
        style: onboardingTitleStyle,
      ),
      const SizedBox(height: 12),
      const Text(
        'Ketuk satu pilihan untuk lanjut.',
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
