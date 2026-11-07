import 'package:flutter/material.dart';

/// Palette supplied for the Profile and History designs.
abstract final class PersonalColors {
  static const primary = Color(0xFF0D6E6B);
  static const ink = Color(0xFF142625);
  static const secondary = Color(0xFF5E7170);
  static const background = Color(0xFFF3F9F8);
  static const soft = Color(0xFFE6F4F3);
  static const chip = Color(0xFFD8EFEF);
  static const border = Color(0xFFE4ECEB);
}

class PersonalPage extends StatelessWidget {
  const PersonalPage({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PersonalColors.background,
    body: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
            children: [
              const Text(
                'nutrilens',
                style: TextStyle(
                  color: PersonalColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
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
            ],
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
      boxShadow: const [
        BoxShadow(
          color: Color(0x060D6E6B),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
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
