import 'package:flutter/material.dart';

import '../../models/nutrition_profile.dart';
import '../../shared/widgets/personal_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.profile, required this.onEdit, super.key});
  final NutritionProfile profile;
  final VoidCallback onEdit;

  void _info(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PersonalPage(
    title: 'Profil & pengaturan',
    subtitle: 'Pilihanmu, jadi fokusmu. Atur pengalaman nutrisi yang sesuai denganmu.',
    children: [
      PersonalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: PersonalColors.chip,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: PersonalColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Profil kamu' : profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: PersonalColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.age == null
                            ? 'Kenali pilihan makanmu'
                            : '${profile.age} tahun',
                        style: const TextStyle(color: PersonalColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profil nutrisi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PersonalColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const PersonalHeading('Prioritas nutrisi'),
      PersonalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.priorities.isEmpty)
              const Text('Belum ada prioritas yang dipilih.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final priority in profile.priorities)
                    Chip(
                      label: Text(priority),
                      avatar: const Icon(Icons.check, size: 16),
                      backgroundColor: PersonalColors.soft,
                      side: BorderSide.none,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'Fokus untuk memahami nutrisi, bukan mengubah nilai nutrisi makanan.',
              style: TextStyle(color: PersonalColors.secondary, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const PersonalHeading('Preferensi makanan'),
      PersonalCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.restaurant_outlined,
              color: PersonalColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(profile.preference ?? 'Belum dipilih · opsional'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const PersonalHeading('Pengaturan'),
      PersonalCard(
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.volume_up_outlined,
                color: PersonalColors.secondary,
              ),
              title: Text('Audio hasil analisis'),
              subtitle: Text('Belum tersedia'),
            ),
            const Divider(color: PersonalColors.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.shield_outlined,
                color: PersonalColors.primary,
              ),
              title: const Text('Privasi dan data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _info(
                context,
                'Privasi dan data',
                'Profil hanya disimpan selama sesi aplikasi ini. Data tidak dikirim '
                    'ke server dan hilang saat aplikasi dimulai ulang. '
                    'Usia dan preferensi makanan boleh dikosongkan. '
                    'Profil belum digunakan oleh mesin analisis nutrisi.',
              ),
            ),
            const Divider(color: PersonalColors.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.info_outline,
                color: PersonalColors.primary,
              ),
              title: const Text('Tentang NutriLens'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _info(
                context,
                'Tentang NutriLens',
                'NutriLens membantu memahami informasi dan trade-off nutrisi '
                    'berdasarkan prioritasmu. Bukan layanan diagnosis atau saran medis.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Tersimpan selama sesi ini saja.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PersonalColors.secondary, fontSize: 12),
      ),
    ],
  );
}
