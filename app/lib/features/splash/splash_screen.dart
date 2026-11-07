import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/local_app_state.dart';

/// Halaman pembuka (Splash Screen) NutriSee.
/// Menampilkan identitas visual merek, logo aplikasi resmi, dan tagline
/// sebelum mengarahkan pengguna ke alur Login/Onboarding atau Beranda.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2000),
    this.onFinish,
  });

  /// Durasi tampilan splash screen sebelum navigasi otomatis.
  /// Dapat disetel ke [Duration.zero] untuk keperluan pengujian unit/widget.
  final Duration duration;

  /// Callback opsional saat durasi splash selesai, berguna untuk pengujian.
  final VoidCallback? onFinish;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    if (widget.duration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateNext();
      });
    } else {
      _timer = Timer(widget.duration, () {
        _navigateNext();
      });
    }
  }

  void _navigateNext() {
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    final hasPriorities = profileSession.value.priorities.isNotEmpty;
    try {
      if (hasPriorities) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    } catch (_) {
      // Diabaikan jika dijalankan di widget test tanpa provider GoRouter.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 16),
                      // Konten Tengah: Logo, Nama Aplikasi & Tagline
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.heroBackground.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/icons/iconaplikasi.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'nutrisee',
                                style: TextStyle(
                                  color: AppColors.heroBackground,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Personalized Nutrition AI',
                                  style: TextStyle(
                                    color: AppColors.heroBackground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Pahami kandungan, pilih sesuai prioritasmu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Konten Bawah: Indikator & Versi
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                                backgroundColor: AppColors.mint,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'NutriSee · Hackathon MVP',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
