import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'navigation/top_nav.dart';

/// Palette supplied for the Profile and History designs.
abstract final class PersonalColors {
  static const primary = AppColors.heroBackground;
  static const ink = AppColors.textPrimary;
  static const secondary = AppColors.textSecondary;
  static const background = AppColors.surface;
  static const soft = AppColors.mint;
  static const chip = Color(0xFFD6F2EF);
  static const border = AppColors.border;
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
                  TopNav(onBack: onBack),
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
                            fontSize: 14,
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
                  if (dockFooter) footer!,
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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: PersonalColors.border, width: 1.2),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: child,
    ),
  );
}

class PersonalHeading extends StatelessWidget {
  const PersonalHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: PersonalColors.ink,
      ),
    ),
  );
}
