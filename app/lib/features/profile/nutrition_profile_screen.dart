import 'package:flutter/material.dart';

import '../../models/nutrition_profile.dart';
import '../../shared/widgets/personal_page.dart';
import '../onboarding/onboarding_preference_screen.dart';

class NutritionProfileScreen extends StatefulWidget {
  const NutritionProfileScreen({
    required this.profile,
    required this.onSave,
    required this.onCancel,
    super.key,
  });
  final NutritionProfile profile;
  final ValueChanged<NutritionProfile> onSave;
  final VoidCallback onCancel;

  @override
  State<NutritionProfileScreen> createState() => _NutritionProfileScreenState();
}

class _NutritionProfileScreenState extends State<NutritionProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _age = TextEditingController(
    text: widget.profile.age?.toString() ?? '',
  );
  late final _priorities = widget.profile.priorities.toSet();
  late String? _preference = widget.profile.preference;
  bool _missingPriority = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    final valid = _form.currentState!.validate();
    setState(() => _missingPriority = _priorities.isEmpty);
    if (!valid || _missingPriority) return;
    widget.onSave(
      NutritionProfile(
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()),
        preference: _preference,
        priorities: NutritionProfile.priorityOptions.where(
          _priorities.contains,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PersonalPage(
    title: 'Profil nutrisi',
    subtitle: 'Pilih yang penting untukmu. Informasi dasar boleh dilewati.',
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PersonalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PersonalHeading('Informasi dasar'),
                  TextFormField(
                    controller: _name,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama panggilan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) > 60
                        ? 'Gunakan maksimal 60 karakter.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Usia (opsional)',
                      suffixText: 'tahun',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final age = int.tryParse(value.trim());
                      return age == null || age < 1 || age > 120
                          ? 'Isi usia 1–120 tahun atau kosongkan.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Usia hanya menjadi informasi profil; tidak menentukan target nutrisi.',
                    style: TextStyle(color: PersonalColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PersonalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PersonalHeading('Prioritas nutrisi'),
                  const Text('Pilih satu atau lebih. Bisa diubah kapan saja.'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final priority in NutritionProfile.priorityOptions)
                        FilterChip(
                          label: Text(priority),
                          selected: _priorities.contains(priority),
                          selectedColor: PersonalColors.chip,
                          onSelected: (selected) => setState(() {
                            selected
                                ? _priorities.add(priority)
                                : _priorities.remove(priority);
                            _missingPriority = _priorities.isEmpty;
                          }),
                        ),
                    ],
                  ),
                  if (_missingPriority) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih minimal satu prioritas.',
                      semanticsLabel: 'Pilih minimal satu prioritas.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            PersonalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PersonalHeading('Preferensi makanan'),
                  const Text('Opsional. Pilih yang paling dekat denganmu.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final choice in OnboardingPreferenceScreen.choices)
                        ChoiceChip(
                          label: Text(choice.title),
                          selected: _preference == choice.title,
                          selectedColor: PersonalColors.chip,
                          onSelected: (selected) => setState(
                            () => _preference = selected ? choice.title : null,
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _preference = null),
                    child: const Text('Kosongkan preferensi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilihan disimpan selama sesi aplikasi ini saja, tidak dikirim ke server.',
              style: TextStyle(color: PersonalColors.secondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: PersonalColors.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Simpan profil'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: widget.onCancel, child: const Text('Batal')),
          ],
        ),
      ),
    ],
  );
}
