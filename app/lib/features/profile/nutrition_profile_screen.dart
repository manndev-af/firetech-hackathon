import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/nutrition_profile.dart';
import '../../shared/widgets/personal_page.dart';
import '../onboarding/onboarding_preference_screen.dart';
import 'widgets/profile_options.dart';

enum ProfileEditSection { all, identity, personalization }

class NutritionProfileScreen extends StatefulWidget {
  const NutritionProfileScreen({
    required this.profile,
    required this.onSave,
    required this.onCancel,
    this.section = ProfileEditSection.all,
    this.inline = false,
    super.key,
  });
  final NutritionProfile profile;
  final ProfileEditSection section;
  final bool inline;
  final ValueChanged<NutritionProfile> onSave;
  final VoidCallback onCancel;

  @override
  State<NutritionProfileScreen> createState() => _NutritionProfileScreenState();
}

class _NutritionProfileScreenState extends State<NutritionProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _prioritySection = GlobalKey();
  final _basicSection = GlobalKey();
  final _measureSection = GlobalKey();
  final _allergySection = GlobalKey();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _age = TextEditingController(
    text: widget.profile.age?.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: _number(widget.profile.heightCm),
  );
  late final _weight = TextEditingController(
    text: _number(widget.profile.weightKg),
  );
  late final _other = TextEditingController(
    text: widget.profile.otherAllergies,
  );
  late final _priorities = widget.profile.priorities.toSet();
  late final _allergies = widget.profile.allergies.toSet();
  late String? _preference = widget.profile.preference;
  late String? _pattern = widget.profile.eatingPattern;
  late bool _halal = widget.profile.prefersHalal;
  late AllergyStatus _allergyStatus = widget.profile.allergyStatus;
  bool _missingPriority = false;
  bool _missingAllergy = false;
  bool _allowLeave = false;
  bool _leaving = false;

  static String _number(double? value) => value == null
      ? ''
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
  double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  bool get _dirty =>
      _name.text.trim() != widget.profile.name ||
      _age.text.trim() != (widget.profile.age?.toString() ?? '') ||
      _height.text.trim() != _number(widget.profile.heightCm) ||
      _weight.text.trim() != _number(widget.profile.weightKg) ||
      _other.text.trim() != widget.profile.otherAllergies ||
      !setEquals(_priorities, widget.profile.priorities.toSet()) ||
      !setEquals(_allergies, widget.profile.allergies.toSet()) ||
      _preference != widget.profile.preference ||
      _pattern != widget.profile.eatingPattern ||
      _halal != widget.profile.prefersHalal ||
      _allergyStatus != widget.profile.allergyStatus;

  @override
  void dispose() {
    for (final controller in [_name, _age, _height, _weight, _other]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_leaving) return;
    _leaving = true;
    final discard =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Buang perubahan?'),
                content: const Text('Perubahan profil ini belum disimpan.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Lanjut mengedit'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Buang perubahan'),
                  ),
                ],
              ),
            ) ==
            true;
    _leaving = false;
    if (!mounted || !discard) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCancel();
    });
  }

  String? _measureError(String? value, double upper, String unit) {
    if (value == null || value.trim().isEmpty) return null;
    final number = _decimal(value);
    if (number == null || !number.isFinite || number <= 0 || number > upper) {
      return 'Isi angka lebih dari 0 sampai ${upper.toInt()} $unit atau kosongkan.';
    }
    return null;
  }

  String? _ageError(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final age = int.tryParse(value.trim());
    return age == null || age < 1 || age > 120
        ? 'Isi usia 1–120 tahun atau kosongkan.'
        : null;
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    setState(() {
      _missingPriority =
          widget.section != ProfileEditSection.identity && _priorities.isEmpty;
      _missingAllergy =
          widget.section != ProfileEditSection.identity &&
          _allergyStatus == AllergyStatus.listed &&
          _allergies.isEmpty &&
          _other.text.trim().isEmpty;
    });
    if (!valid || _missingPriority || _missingAllergy) {
      final target = _missingPriority
          ? _prioritySection
          : _ageError(_age.text) != null || _name.text.trim().length > 60
          ? _basicSection
          : _measureError(_height.text, 300, 'cm') != null ||
                _measureError(_weight.text, 700, 'kg') != null
          ? _measureSection
          : _allergySection;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && target.currentContext != null) {
          Scrollable.ensureVisible(
            target.currentContext!,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
      return;
    }
    final identity = widget.section == ProfileEditSection.identity;
    final personalization =
        widget.section == ProfileEditSection.personalization;
    final result = NutritionProfile(
      name: personalization ? widget.profile.name : _name.text.trim(),
      age: personalization
          ? widget.profile.age
          : int.tryParse(_age.text.trim()),
      preference: _preference,
      priorities: identity
          ? widget.profile.priorities
          : NutritionProfile.priorityOptions.where(_priorities.contains),
      heightCm: personalization
          ? widget.profile.heightCm
          : _decimal(_height.text),
      weightKg: personalization
          ? widget.profile.weightKg
          : _decimal(_weight.text),
      eatingPattern: _pattern,
      prefersHalal: _halal,
      allergyStatus: _allergyStatus,
      allergies: identity
          ? widget.profile.allergies
          : _allergyStatus == AllergyStatus.listed
          ? _allergies
          : const [],
      otherAllergies: identity
          ? widget.profile.otherAllergies
          : _allergyStatus == AllergyStatus.listed
          ? _other.text.trim()
          : '',
    );
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSave(result);
    });
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? unit,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: unit,
    filled: true,
    fillColor: PersonalColors.soft,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    labelStyle: const TextStyle(fontSize: 14, color: PersonalColors.secondary),
    hintStyle: const TextStyle(fontSize: 16, color: PersonalColors.secondary),
    suffixStyle: const TextStyle(fontSize: 14, color: PersonalColors.secondary),
    errorMaxLines: 3,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: PersonalColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: PersonalColors.primary, width: 2),
    ),
  );

  Widget _layout({
    required String title,
    required String subtitle,
    required VoidCallback onBack,
    required Widget footer,
    required List<Widget> children,
  }) {
    if (widget.inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...children, const SizedBox(height: 24), footer],
      );
    }
    return PersonalPage(
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      footer: footer,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowLeave || (!widget.inline && !_dirty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _cancel();
    },
    child: _layout(
      title: 'Profil nutrisi',
      subtitle: 'Pilih fokusmu. Lengkapi informasi lain jika kamu ingin.',
      onBack: _cancel,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: PersonalColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              widget.section == ProfileEditSection.personalization
                  ? 'Simpan personalisasi'
                  : 'Simpan profil',
            ),
          ),
          TextButton(
            onPressed: _cancel,
            child: Text(widget.inline ? 'Kembali' : 'Batal'),
          ),
        ],
      ),
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.section != ProfileEditSection.identity) ...[
                Column(
                  key: _prioritySection,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PersonalHeading('1. Prioritas nutrisi'),
                    const Text(
                      'Pilih minimal satu. Semua nutrisi tetap bisa dilihat.',
                    ),
                    const SizedBox(height: 16),
                    for (final priority in NutritionProfile.priorityOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: _priorities.contains(priority)
                              ? PersonalColors.soft
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _priorities.contains(priority)
                                  ? PersonalColors.primary
                                  : PersonalColors.border,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _priorities.contains(priority),
                            activeColor: PersonalColors.primary,
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(
                              priorityCopy[priority]!.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              priorityCopy[priority]!.detail,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: PersonalColors.secondary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onChanged: (value) => setState(() {
                              value!
                                  ? _priorities.add(priority)
                                  : _priorities.remove(priority);
                              _missingPriority =
                                  widget.section !=
                                      ProfileEditSection.identity &&
                                  _priorities.isEmpty;
                            }),
                          ),
                        ),
                      ),
                    if (_missingPriority)
                      const _FormError('Pilih minimal satu prioritas.'),
                  ],
                ),
                const SizedBox(height: 24),
                const PersonalHeading('2. Pilihan makanan'),
                const Text(
                  'Opsional. Untuk memberi konteks pada pilihan makananmu.',
                ),
                const SizedBox(height: 16),
                PersonalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Keseharian',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final choice
                              in OnboardingPreferenceScreen.choices)
                            ChoiceChip(
                              label: Text(choice.title),
                              selected: _preference == choice.title,
                              selectedColor: PersonalColors.chip,
                              onSelected: (selected) => setState(
                                () => _preference = selected
                                    ? choice.title
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(() => _preference = null),
                          child: const Text('Kosongkan preferensi'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pola makan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _pattern,
                        isExpanded: true,
                        decoration: _fieldDecoration('Pola makan (opsional)'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Belum dipilih'),
                          ),
                          for (final pattern in NutritionProfile.eatingPatterns)
                            DropdownMenuItem(
                              value: pattern,
                              child: Text(pattern),
                            ),
                        ],
                        onChanged: (value) => setState(() => _pattern = value),
                      ),
                      if (_pattern != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            eatingPatternCopy[_pattern]!,
                            style: const TextStyle(
                              color: PersonalColors.secondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _halal,
                        activeColor: PersonalColors.primary,
                        title: const Text('Utamakan makanan halal'),
                        subtitle: const Text(
                          'Preferensi ini bukan verifikasi atau sertifikasi halal.',
                        ),
                        onChanged: (value) => setState(() => _halal = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  key: _allergySection,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PersonalHeading('3. Alergi makanan'),
                    const Text(
                      'Opsional. Catat bahan yang perlu diperhatikan.',
                    ),
                    const SizedBox(height: 16),
                    PersonalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<AllergyStatus>(
                            initialValue: _allergyStatus,
                            isExpanded: true,
                            decoration: _fieldDecoration('Informasi alergi'),
                            items: const [
                              DropdownMenuItem(
                                value: AllergyStatus.unknown,
                                child: Text('Belum diisi'),
                              ),
                              DropdownMenuItem(
                                value: AllergyStatus.noneKnown,
                                child: Text('Tidak ada yang diketahui'),
                              ),
                              DropdownMenuItem(
                                value: AllergyStatus.listed,
                                child: Text('Ada bahan yang dihindari'),
                              ),
                            ],
                            onChanged: (value) => setState(() {
                              _allergyStatus = value!;
                              _missingAllergy = false;
                            }),
                          ),
                          if (_allergyStatus == AllergyStatus.listed) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final allergy
                                    in NutritionProfile.allergyOptions)
                                  FilterChip(
                                    label: Text(allergy),
                                    selected: _allergies.contains(allergy),
                                    selectedColor: PersonalColors.chip,
                                    onSelected: (selected) => setState(() {
                                      selected
                                          ? _allergies.add(allergy)
                                          : _allergies.remove(allergy);
                                    }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('other-allergies'),
                              controller: _other,
                              maxLength: 120,
                              decoration: const InputDecoration(
                                labelText: 'Bahan lain (opsional)',
                                hintText: 'Contoh: wijen',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) > 120
                                  ? 'Gunakan maksimal 120 karakter.'
                                  : null,
                            ),
                            if (_missingAllergy)
                              const _FormError(
                                'Pilih bahan atau tulis bahan lain.',
                              ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'Pencocokan alergen belum tersedia. Data bahan yang tidak lengkap tidak berarti makanan bebas alergen.',
                            style: TextStyle(
                              color: PersonalColors.secondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              if (widget.section != ProfileEditSection.personalization) ...[
                Column(
                  key: _basicSection,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PersonalHeading('Informasi profil'),
                    const Text(
                      'Opsional. Nama untuk sapaan; usia sebagai informasi profil.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profile-name'),
                      controller: _name,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      maxLength: 60,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        'Nama panggilan (opsional)',
                        hint: 'Nama yang ingin kamu gunakan',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) => (value?.trim().length ?? 0) > 60
                          ? 'Gunakan maksimal 60 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profile-age'),
                      controller: _age,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        'Usia (opsional)',
                        unit: 'tahun',
                        hint: 'Contoh: 22',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: _ageError,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  key: _measureSection,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PersonalHeading('Ukuran tubuh'),
                    const Text(
                      'Opsional. Belum digunakan untuk menghitung target kalori, BMI, atau target berat.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profile-height'),
                      controller: _height,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        'Tinggi badan (opsional)',
                        unit: 'cm',
                        hint: 'Contoh: 165',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) => _measureError(value, 300, 'cm'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('profile-weight'),
                      controller: _weight,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        'Berat badan (opsional)',
                        unit: 'kg',
                        hint: 'Contoh: 58,5',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) => _measureError(value, 700, 'kg'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Dengan menyimpan, pilihanmu berlaku selama sesi ini saja. Data tidak dikirim ke server dan hilang saat aplikasi dimulai ulang.',
                style: TextStyle(color: PersonalColors.secondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FormError extends StatelessWidget {
  const _FormError(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    ),
  );
}
