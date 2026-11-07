import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrilens/shared/widgets/navigation/bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,

      bottomNavigationBar: BottomNav(
        currentIndex: const [0, 2, 3][navigationShell.currentIndex],

        onTap: (index) {
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Insight belum tersedia.')),
            );
            return;
          }
          final branch = const {0: 0, 2: 1, 3: 2}[index]!;
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },

        onAddTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera makanan belum tersedia.')),
          );
        },
      ),
    );
  }
}
