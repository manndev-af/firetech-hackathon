import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import 'onboarding_focus_screen.dart';
import 'onboarding_preference_screen.dart';
import 'onboarding_finish_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _focus = 'Gula';
  String? _preference = 'Masakan rumahan';

  void _back() {
    if (_step == 0) {
      context.go(AppRoutes.login);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: switch (_step) {
      0 => OnboardingFocusScreen(
        selected: _focus,
        onChanged: (value) => setState(() => _focus = value),
        onNext: () => setState(() => _step = 1),
        onBack: _back,
      ),
      1 => OnboardingPreferenceScreen(
        selected: _preference,
        onChanged: (value) => setState(() => _preference = value),
        onNext: () => setState(() => _step = 2),
        onSkip: () => setState(() {
          _preference = null;
          _step = 2;
        }),
        onBack: _back,
      ),
      _ => OnboardingFinishScreen(
        focus: _focus,
        preference: _preference,
        onHome: () => context.go(AppRoutes.home),
      ),
    },
  );
}
