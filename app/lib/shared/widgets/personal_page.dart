import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Palette supplied for the Profile and History designs.
abstract final class PersonalColors {
  static const primary = AppColors.heroBackground;
  static const ink = AppColors.textPrimary;
  static const secondary = AppColors.textSecondary;
  static const background = AppColors.surface;
  static const soft = Color(0xFFE6F4F3);
  static const chip = Color(0xFFD8EFEF);
  static const border = Color(0xFFE4ECEB);
}

class PersonalPage extends StatelessWidget {
  const PersonalPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
    this.footer,
    this.controller,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PersonalColors.background,
    body: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dockFooter =
                  footer != null &&
                  constraints.maxHeight >= 600 &&
                  MediaQuery.viewInsetsOf(context).bottom == 0;
              return Column(
                children: [
                  if (onBack != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        dockFooter ? 24 : 140,
                      ),
                      children: [
                        if (onBack == null)
                          const Text(
                            'nutrilens',
                            style: TextStyle(
                              color: PersonalColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: PersonalColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: PersonalColors.secondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...children,
                        if (footer != null && !dockFooter) ...[
                          const SizedBox(height: 24),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                  if (dockFooter)
                    Material(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          12,
                          24,
                          MediaQuery.viewInsetsOf(context).bottom > 0
                              ? 12
                              : 120,
                        ),
                        child: footer!,
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
}

class PersonalCard extends StatelessWidget {
  const PersonalCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PersonalColors.border),
    ),
    child: Material(color: Colors.transparent, child: child),
  );
}

class PersonalHeading extends StatelessWidget {
  const PersonalHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: PersonalColors.ink,
      ),
    ),
  );
}
