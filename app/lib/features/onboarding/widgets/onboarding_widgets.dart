import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    required this.content,
    required this.footer,
    this.bottomSpace = 24,
    super.key,
  });
  final List<Widget> content;
  final List<Widget> footer;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomSpace),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...content,
                            const SizedBox(height: 40),
                            const Spacer(),
                            ...footer,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({required this.step, required this.onBack, super.key});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton.filledTonal(
        tooltip: 'Kembali',
        onPressed: onBack,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
        ),
        icon: const Icon(Icons.arrow_back),
      ),
      Text(
        '0$step / 02',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 16),
    ],
  );
}

class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.showUnselectedIcon = true,
    super.key,
  });
  final String title;
  final String description;
  final bool selected;
  final bool showUnselectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.mint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? AppColors.cyan : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected || showUnselectedIcon) ...[
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: Icon(
                      selected ? Icons.check : Icons.radio_button_unchecked,
                      size: 28,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

const onboardingTitleStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 30,
  height: 1.35,
  fontWeight: FontWeight.w700,
);
const onboardingBodyStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 14,
  height: 1.4,
);
