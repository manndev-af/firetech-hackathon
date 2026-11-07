import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const _ink = Color(0xFF142625);
  static const _teal = Color(0xFF0B6663);
  static const _muted = Color(0xFF5E7170);
  static const _pale = Color(0xFFE6F4F3);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        children: [
          const Text(
            'Pilihan berikutnya,\nlebih sesuai kamu.',
            style: TextStyle(
              color: _ink,
              fontSize: 29,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Teman memahami makanan sehari-hari.',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 27),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _pale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fokus gula · dari catatanmu',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gunakan catatan makan untuk memberi konteks pada percakapan.',
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Mau bahas apa?',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _ExploreTile(
            title: 'Bandingkan dua pilihan',
            subtitle: 'Lihat porsi, gula, protein, dan trade-off',
            onTap: () => context.push(AppRoutes.comparison),
          ),
          const SizedBox(height: 15),
          _ExploreTile(
            title: 'Lihat pola catatanku',
            subtitle: 'Pahami makanan yang sering kamu catat',
            onTap: () => context.push(AppRoutes.assistant, extra: true),
          ),
          const SizedBox(height: 15),
          _ExploreTile(
            title: 'Tanya soal makanan',
            subtitle: 'Mulai dari yang sedang kamu pertimbangkan',
            onTap: () => context.push(AppRoutes.assistant),
          ),
        ],
      ),
    ),
  );
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE4ECEB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF142625),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5E7170),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0B6663)),
          ],
        ),
      ),
    ),
  );
}
