import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/nutrition_profile.dart';
import '../../shared/widgets/personal_page.dart';
import 'nutrition_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profile,
    required this.onSave,
    this.audioPreference,
    super.key,
  });
  final NutritionProfile profile;
  final ValueChanged<NutritionProfile> onSave;
  final ValueNotifier<bool>? audioPreference;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ValueNotifier<bool> _localAudio = ValueNotifier(false);
  ValueNotifier<bool> get _audio => widget.audioPreference ?? _localAudio;
  NutritionProfile get profile => widget.profile;
  ProfileEditSection? _editing;
  final _scroll = ScrollController();

  void _closeEditor() {
    setState(() => _editing = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Widget _editor(ProfileEditSection section) => NutritionProfileScreen(
    key: ValueKey(section),
    profile: profile,
    section: section,
    inline: true,
    onCancel: _closeEditor,
    onSave: (value) {
      widget.onSave(value);
      _closeEditor();
    },
  );

  @override
  void dispose() {
    _localAudio.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PersonalPage(
    controller: _scroll,
    title: 'Profil kamu',
    subtitle: 'Pilihan nutrisi yang lebih personal.',
    children: [
      // 1. User Identity Hero Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PersonalColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.heroBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.mint,
                child: Icon(
                  Icons.person_rounded,
                  color: PersonalColors.primary,
                  size: 28,
                ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PersonalColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.age == null
                        ? 'Lengkapi profilmu'
                        : '${profile.age} tahun',
                    style: const TextStyle(
                      fontSize: 14,
                      color: PersonalColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit profil',
              onPressed: _editing == null
                  ? () => setState(() => _editing = ProfileEditSection.identity)
                  : null,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PersonalColors.soft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: PersonalColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      if (_editing == ProfileEditSection.identity)
        _editor(ProfileEditSection.identity),

      if (_editing != ProfileEditSection.identity) ...[
        const PersonalHeading('Personalisasi'),
        if (_editing == ProfileEditSection.personalization)
          _editor(ProfileEditSection.personalization)
        else
          PersonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group 1: Fokus Nutrisi
                const Text(
                  'Fokus nutrisi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PersonalColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in profile.priorities)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: PersonalColors.soft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PersonalColors.primary,
                          ),
                        ),
                      ),
                    if (profile.priorities.isEmpty)
                      const Text(
                        'Belum dipilih',
                        style: TextStyle(
                          fontSize: 14,
                          color: PersonalColors.secondary,
                        ),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: PersonalColors.border, height: 1),
                ),

                // Group 2: Pola & Preferensi Makan
                _detail(
                  'Pilihan makanan',
                  profile.preference ?? 'Belum dipilih',
                  icon: Icons.restaurant_outlined,
                ),
                _detail(
                  'Pola makan',
                  profile.eatingPattern ?? 'Belum dipilih',
                  icon: Icons.eco_outlined,
                ),
                _detail(
                  'Preferensi halal',
                  profile.prefersHalal
                      ? 'Mengutamakan makanan halal'
                      : 'Belum dipilih',
                  icon: Icons.verified_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: PersonalColors.border, height: 1),
                ),

                // Group 3: Alergi Makanan
                _detail(
                  'Alergi makanan',
                  switch (profile.allergyStatus) {
                    AllergyStatus.unknown => 'Belum diisi',
                    AllergyStatus.noneKnown => 'Tidak ada yang diketahui',
                    AllergyStatus.listed =>
                      [
                            ...profile.allergies,
                            if (profile.otherAllergies.isNotEmpty)
                              profile.otherAllergies,
                          ].join(', ').isEmpty
                          ? 'Bahan belum diisi'
                          : [
                              ...profile.allergies,
                              if (profile.otherAllergies.isNotEmpty)
                                profile.otherAllergies,
                            ].join(', '),
                  },
                  icon: profile.allergyStatus == AllergyStatus.listed
                      ? Icons.warning_amber_rounded
                      : Icons.health_and_safety_outlined,
                  isAlert: profile.allergyStatus == AllergyStatus.listed,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: PersonalColors.border, height: 1),
                ),

                // Action to edit personalization
                TextButton.icon(
                  onPressed: () => setState(
                    () => _editing = ProfileEditSection.personalization,
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'Lihat detail',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: PersonalColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],

      if (_editing == null) ...[
        const PersonalHeading('Pengaturan'),
        PersonalCard(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _audio,
                builder: (context, enabled, _) => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PersonalColors.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      color: PersonalColors.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Audio analisis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    enabled
                        ? 'Aktif · bacakan ringkasan analisis'
                        : 'Nonaktif · baca ringkasan tanpa suara',
                    style: const TextStyle(
                      fontSize: 14,
                      color: PersonalColors.secondary,
                    ),
                  ),
                  activeTrackColor: PersonalColors.primary,
                  activeThumbColor: Colors.white,
                  value: enabled,
                  onChanged: (value) => _audio.value = value,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: PersonalColors.border, height: 1),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PersonalColors.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: PersonalColors.primary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Privasi dan data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Data profil tersimpan di perangkat ini',
                  style: TextStyle(
                    fontSize: 13,
                    color: PersonalColors.secondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: PersonalColors.secondary,
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privasi dan data'),
                    content: const Text(
                      'Profil, pilihan audio, foto, teks OCR, dan hasil analisis disimpan di perangkat ini. Saat analisis diminta, foto yang diperkecil, teks OCR, dan prioritas nutrisi dikirim ke layanan analisis. Nama, usia, tinggi, berat, dan alergi tidak dikirim. Kamu dapat mengosongkan informasi opsional melalui Edit profil atau detail Personalisasi. Menghapus data aplikasi akan menghapus catatan lokal.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _detail(
    String label,
    String value, {
    IconData? icon,
    bool isAlert = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isAlert
                    ? const Color(0xFFDC2626)
                    : PersonalColors.primary,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: PersonalColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isAlert ? const Color(0xFFDC2626) : PersonalColors.ink,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
