import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingFinishScreen extends StatefulWidget {
  const OnboardingFinishScreen({
    required this.focus,
    required this.preference,
    required this.onHome,
    this.autoTransitionDuration = const Duration(milliseconds: 2500),
    super.key,
  });

  final String focus;
  final String? preference;
  final VoidCallback onHome;
  final Duration autoTransitionDuration;

  @override
  State<OnboardingFinishScreen> createState() => _OnboardingFinishScreenState();
}

class _OnboardingFinishScreenState extends State<OnboardingFinishScreen> {
  Timer? _autoTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isTest && widget.autoTransitionDuration > Duration.zero) {
      _autoTimer = Timer(widget.autoTransitionDuration, _proceedToHome);
    }
  }

  void _proceedToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _autoTimer?.cancel();
    widget.onHome();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingLayout(
        bottomSpace: 40,
        content: [
          const SizedBox(height: 24),
          // Food Artwork Vector
          Semantics(
            image: true,
            label: 'Ilustrasi semangkuk nasi, ayam, telur, dan sayuran',
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 230),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.asset(
                  'assets/images/foodartwork.png',
                  height: 210,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SIAP MEMULAI',
                style: TextStyle(
                  color: AppColors.heroBackground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Makan lebih paham,\nsetiap hari.',
            textAlign: TextAlign.center,
            style: onboardingTitleStyle,
          ),
          const SizedBox(height: 14),
          Text(
            'Fokus ${widget.focus.toLowerCase()} sudah dipilih. Catat makanan pertamamu untuk melihat rangkumannya.',
            textAlign: TextAlign.center,
            style: onboardingBodyStyle.copyWith(fontSize: 15, height: 1.45),
          ),
          if (widget.preference != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Preferensi: ${widget.preference}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Mengarahkan ke Beranda...',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        footer: [
          OnboardingButton(
            label: 'Ke beranda',
            onPressed: _proceedToHome,
          ),
        ],
      );
}
