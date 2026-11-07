import 'package:flutter/material.dart';

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
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PersonalColors.soft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person_outline_rounded,
                color: PersonalColors.primary,
                size: 28,
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
                      fontWeight: FontWeight.w600,
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
              icon: const Icon(
                Icons.edit_outlined,
                color: PersonalColors.primary,
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
                const Text(
                  'Fokus nutrisi',
                  style: TextStyle(
                    fontSize: 14,
                    color: PersonalColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in profile.priorities)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: PersonalColors.soft,
                          borderRadius: BorderRadius.circular(12),
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
                    if (profile.priorities.isEmpty) const Text('Belum dipilih'),
                  ],
                ),
                const SizedBox(height: 20),
                _detail(
                  'Pilihan makanan',
                  profile.preference ?? 'Belum dipilih',
                ),
                _detail('Pola makan', profile.eatingPattern ?? 'Belum dipilih'),
                _detail(
                  'Preferensi halal',
                  profile.prefersHalal
                      ? 'Mengutamakan makanan halal'
                      : 'Belum dipilih',
                ),
                _detail('Alergi makanan', switch (profile.allergyStatus) {
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
                }),
                const Divider(color: PersonalColors.border),
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
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
      if (_editing == null) ...[
        const PersonalHeading('Pengaturan'),
        ValueListenableBuilder<bool>(
          valueListenable: _audio,
          builder: (context, enabled, _) => SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.volume_up_outlined,
              color: PersonalColors.primary,
            ),
            title: const Text(
              'Audio analisis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              enabled
                  ? 'Aktif \u00b7 bacakan ringkasan analisis'
                  : 'Nonaktif \u00b7 baca ringkasan tanpa suara',
              style: const TextStyle(
                fontSize: 14,
                color: PersonalColors.secondary,
              ),
            ),
            activeThumbColor: PersonalColors.primary,
            value: enabled,
            onChanged: (value) => _audio.value = value,
          ),
        ),
        const Divider(color: PersonalColors.border),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.shield_outlined,
            color: PersonalColors.primary,
          ),
          title: const Text('Privasi dan data', style: TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Privasi dan data'),
              content: const Text(
                'Profil dan pilihan audio disimpan selama sesi ini. Data tidak dikirim ke server. Kamu dapat mengosongkan informasi opsional melalui Edit profil atau detail Personalisasi.',
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
    ],
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: PersonalColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
