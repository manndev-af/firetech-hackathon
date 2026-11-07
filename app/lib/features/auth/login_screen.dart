import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _continueWithGoogle(BuildContext context) {
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'nutrilens',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The supplied export contains the entire design. Only the
                  // food illustration region is rendered; controls stay native.
                  Semantics(
                    image: true,
                    label: 'Ilustrasi semangkuk nasi, ayam, telur, dan sayuran',
                    child: ExcludeSemantics(
                      child: AspectRatio(
                        aspectRatio: 342 / 310,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final scale = constraints.maxWidth / 342;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: -24 * scale,
                                    top: -120 * scale,
                                    width: 390 * scale,
                                    height: 844 * scale,
                                    child: Image.asset(
                                      'assets/images/login_reference.png',
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Kenali isi piringmu.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pahami makananmu, sesuai hal\nyang ingin kamu perhatikan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _continueWithGoogle(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size.fromHeight(56),
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text(
                        'Lanjutkan dengan Google',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dengan melanjutkan, kamu menyetujui\n'
                    'Ketentuan dan Kebijakan Privasi NutriLens.',
                    style: AppTypography.secondary.copyWith(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Prototipe · login belum terhubung',
                    style: AppTypography.secondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
