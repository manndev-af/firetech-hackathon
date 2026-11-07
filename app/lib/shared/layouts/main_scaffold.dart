import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrilens/shared/widgets/navigation/bottom_nav.dart';

import '../../core/router/route_paths.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,

      bottomNavigationBar: BottomNav(
        currentIndex: navigationShell.currentIndex,

        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },

        onAddTap: () => context.push(AppRoutes.scanner),
      ),
    );
  }
}
