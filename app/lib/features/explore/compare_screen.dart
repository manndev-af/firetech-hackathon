import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F9F8),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0B6663),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dua pilihan,\nbasis yang sama.',
                  style: TextStyle(
                    color: Color(0xFF142625),
                    fontSize: 29,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contoh perbandingan · per 250 ml',
                  style: TextStyle(color: Color(0xFF5E7170), fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data ilustrasi, bukan referensi nutrisi.',
                  style: TextStyle(color: Color(0xFF5E7170), fontSize: 12),
                ),
                const SizedBox(height: 42),
                const Row(
                  children: [
                    Expanded(
                      child: _FoodCard(
                        name: 'Minuman A',
                        sugar: '12 g',
                        protein: 'Protein 4 g',
                        color: Color(0xFFF3F9F8),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _FoodCard(
                        name: 'Minuman B',
                        sugar: '6 g',
                        protein: 'Protein 3 g',
                        color: Color(0xFFE6F4F3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Text(
                  'Lebih sedikit gula,\nprotein juga berbeda.',
                  style: TextStyle(
                    color: Color(0xFF142625),
                    fontSize: 25,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pada contoh ini, B mengandung 6 g gula lebih sedikit dengan protein 1 g lebih rendah. Pilih sesuai hal yang ingin kamu perhatikan.',
                  style: TextStyle(
                    color: Color(0xFF5E7170),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6E6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => context.push(AppRoutes.assistant, extra: true),
                child: const Text('Bahas pilihan ini'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.name,
    required this.sugar,
    required this.protein,
    required this.color,
  });
  final String name, sugar, protein;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    height: 211,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF142625),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          sugar,
          style: const TextStyle(
            color: Color(0xFF0B6663),
            fontSize: 35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          'gula / 250 ml',
          style: TextStyle(color: Color(0xFF5E7170), fontSize: 12),
        ),
        const Spacer(),
        Text(
          protein,
          style: const TextStyle(color: Color(0xFF142625), fontSize: 14),
        ),
      ],
    ),
  );
}
