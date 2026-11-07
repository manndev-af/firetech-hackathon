import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrilens/core/theme/app_colors.dart';

import 'nav_item.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  static const Color primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Mengubah warna background system navigation bar bawah menjadi putih
        systemNavigationBarColor: Colors.white,
        // Mengatur warna ikon navigasi sistem (garis/tombol back-home-recents) agar gelap
        systemNavigationBarIconBrightness: Brightness.dark,
        // Untuk Android O ke atas agar tidak ada warna divider transparan tambahan
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Custom navigation background with notch
                Positioned.fill(
                  child: CustomPaint(
                    painter: BottomNavPainter(
                      barColor: Colors.white,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ),

                // Navigation items
                Positioned(
                  left: 0,
                  right: 0,
                  top: 24,
                  bottom: 4,
                  child: Row(
                    children: [
                      NavItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        index: 0,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),

                      NavItem(
                        icon: Icons.explore_outlined,
                        label: 'Jelajahi',
                        index: 1,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),

                      // Space for center button
                      const SizedBox(width: 76),

                      NavItem(
                        icon: Icons.history_outlined,
                        label: 'History',
                        index: 2,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),

                      NavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        index: 3,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),
                    ],
                  ),
                ),

                // Floating center button with theme gradient and ring
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.heroBackground],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 3.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.heroBackground.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onAddTap,
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  final Color barColor;
  final Color shadowColor;

  BottomNavPainter({required this.barColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = width / 2;

    const radius = 28.0;
    const top = 20.0;
    const notchRadius = 34.0;
    const notchDepth = 80.0;

    final path = Path();

    // Start top-left
    path.moveTo(radius, top);

    // Left notch curve: smoothly cradle the camera button
    path.lineTo(center - notchRadius - 14, top);
    path.cubicTo(
      center - notchRadius + 2,
      top,
      center - notchRadius,
      notchDepth,
      center,
      notchDepth,
    );

    // Right notch curve
    path.cubicTo(
      center + notchRadius,
      notchDepth,
      center + notchRadius - 2,
      top,
      center + notchRadius + 14,
      top,
    );

    // Top-right
    path.lineTo(width - radius, top);
    path.quadraticBezierTo(width, top, width, top + radius);

    // Rounded bottom corners
    path.lineTo(width, height - radius);
    path.quadraticBezierTo(width, height, width - radius, height);
    path.lineTo(radius, height);
    path.quadraticBezierTo(0, height, 0, height - radius);

    // Left side & Top-left curve
    path.lineTo(0, top + radius);
    path.quadraticBezierTo(0, top, radius, top);

    path.close();

    final ambientShadow = Paint()
      ..color = shadowColor.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, ambientShadow);
    canvas.drawShadow(path, shadowColor, 3.0, true);

    // Draw background
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw subtle border matching design theme
    final strokePaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BottomNavPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
