import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';

class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  static const _destinations = <({String label, String path})>[
    (label: 'Splash', path: AppRoutes.splash),
    (label: 'Login', path: AppRoutes.login),
    (label: 'Daftar', path: AppRoutes.register),
    (label: 'Onboarding', path: AppRoutes.onboarding),
    (label: 'Home', path: AppRoutes.home),
    (label: 'Scan makanan', path: AppRoutes.scanner),
    (label: 'Food recognition', path: AppRoutes.recognition),
    (label: 'Konfirmasi porsi', path: AppRoutes.portionConfirmation),
    (label: 'Hasil nutrisi', path: AppRoutes.nutritionResult),
    (label: 'Insight personal', path: AppRoutes.insight),
    (label: 'Perbandingan makanan', path: AppRoutes.comparison),
    (label: 'Riwayat', path: AppRoutes.history),
    (label: 'Nutrition Profile', path: AppRoutes.nutritionProfile),
    (label: 'Profil & pengaturan', path: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriLens AI'),
        leading: context.canPop()
            ? IconButton(
                tooltip: 'Kembali',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Layar ini adalah placeholder routing. Konten produk akan '
                  'ditambahkan pada task implementasi UI terkait.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Navigasi sementara',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final destination in _destinations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(destination.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(destination.path),
              ),
          ],
        ),
      ),
    );
  }
}
