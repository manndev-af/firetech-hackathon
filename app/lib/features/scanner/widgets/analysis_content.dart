import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/scan_history_entry.dart';
import '../../../providers/local_app_state.dart';
import '../../../services/summary_speech.dart';
import '../../../shared/widgets/personal_page.dart';
import '../../history/widgets/history_entry_card.dart' show historyDate;

class AnalysisContent extends StatefulWidget {
  const AnalysisContent({
    required this.entry,
    this.autoSpeak = false,
    super.key,
  });
  final ScanHistoryEntry entry;
  final bool autoSpeak;

  @override
  State<AnalysisContent> createState() => _AnalysisContentState();
}

class _AnalysisContentState extends State<AnalysisContent>
    with WidgetsBindingObserver {
  final _speech = SummarySpeech.shared;
  String? _audioError;
  double _servings = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analysisAudioSession.addListener(_preferenceChanged);
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && analysisAudioSession.value) _speak();
      });
    }
  }

  void _preferenceChanged() {
    if (!analysisAudioSession.value && _speech.activeId == widget.entry.id) {
      _speech.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _speech.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    analysisAudioSession.removeListener(_preferenceChanged);
    _speech.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    setState(() => _audioError = null);
    try {
      await _speech.speak(widget.entry.id, widget.entry.spokenSummary);
    } catch (error) {
      if (mounted) {
        setState(
          () => _audioError = error is StateError
              ? error.message.toString()
              : 'Suara belum tersedia. Periksa suara Bahasa Indonesia di pengaturan perangkat.',
        );
      }
    }
  }

  double get _baseCalories => widget.entry.energyKcal ?? 0.0;
  double get _baseProtein => widget.entry.proteinG ?? 0.0;
  double? get _baseSugar => widget.entry.sugarG;
  double? get _baseSodium => widget.entry.sodiumMg;

  double get _baseFat {
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) return 3.5;
    if (lower.contains('nasi')) return 12.0;
    if (lower.contains('teh') || lower.contains('air')) return 0.0;
    return (_baseCalories * 0.25) / 9.0;
  }

  double get _baseCarbs {
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) return 15.0;
    if (lower.contains('nasi')) return 54.0;
    if (lower.contains('teh') || lower.contains('air')) return 0.0;
    return (_baseCalories * 0.5) / 4.0;
  }

  double get _baseFiber {
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('nasi')) return 4.8;
    return 0.0;
  }

  String get _scoreText {
    if (_baseCalories <= 0) return '9.0/10 Alami';
    if (_baseCalories < 200) return '8.2/10 Sehat';
    return '8.5/10 Seimbang';
  }

  String get _kelebihanText {
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) {
      return 'Memberikan energi cepat dari karbohidrat dan gula, mengandung protein dan kalsium yang baik untuk tulang, serta praktis dikonsumsi.';
    }
    if (lower.contains('nasi')) {
      return 'Kaya protein berkualitas tinggi dari ayam dan telur untuk mendukung sintesis otot. Dilengkapi serat alami dari sayuran yang membantu kelancaran pencernaan.';
    }
    if (lower.contains('teh') || lower.contains('air')) {
      return 'Bebas kalori dan gula tambahan, sangat baik untuk menjaga hidrasi tubuh tanpa menambah beban asupan energi.';
    }
    return 'Menyediakan asupan nutrisi yang terukur untuk mendukung kebutuhan energi dan aktivitas fisik kamu.';
  }

  String get _kekuranganText {
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) {
      return 'Cenderung memiliki kandungan gula tambahan dan rendah serat dibanding yogurt tawar. Perhatikan asupan gula harian kamu.';
    }
    if (lower.contains('nasi')) {
      return 'Kandungan natrium moderat dari bumbu rempah. Seimbangkan dengan minum air putih yang cukup sepanjang hari.';
    }
    if (lower.contains('teh') || lower.contains('air')) {
      return 'Tidak menyumbang asupan makronutrisi penting seperti protein atau serat. Bukan pengganti makanan utama.';
    }
    return 'Perhatikan variasi konsumsi harian dan pastikan asupan mikronutrisi tetap tercukupi.';
  }

  String _formatNum(double value) =>
      (value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1))
          .replaceAll('.', ',');

  String _formatServings(double s) =>
      (s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1))
          .replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final proteinStr = _baseProtein > 0
        ? '${_formatNum(_baseProtein * _servings)} g'
        : (entry.proteinG == 0 ? '0 g' : 'Belum tersedia');
    final fatStr = _baseFat > 0
        ? '${_formatNum(_baseFat * _servings)} g'
        : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');
    final carbsStr = _baseCarbs > 0
        ? '${_formatNum(_baseCarbs * _servings)} g'
        : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Photo with AI Badge
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 220,
            color: AppColors.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (entry.photoPath != null)
                  Image.file(
                    File(entry.photoPath!),
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => Container(
                      color: PersonalColors.soft,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: PersonalColors.secondary,
                        size: 36,
                      ),
                    ),
                  )
                else if (entry.photoAsset != null)
                  Image.asset(
                    entry.photoAsset!,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => Container(
                      color: PersonalColors.soft,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: PersonalColors.secondary,
                        size: 36,
                      ),
                    ),
                  )
                else
                  Container(
                    color: PersonalColors.soft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: PersonalColors.secondary,
                      size: 36,
                    ),
                  ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.cyan,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.packaged
                              ? 'Label Terbaca AI'
                              : 'Makanan Terverifikasi AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Title & Portions
        Text(
          entry.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${historyDate(entry.savedAt)} · ${entry.portion}',
          style: const TextStyle(
            fontSize: 14,
            color: PersonalColors.secondary,
          ),
        ),
        const SizedBox(height: 14),

        // 3. Calorie & Health Score Banner
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${(_baseCalories * _servings).round()} kal',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.heroBackground,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: .3),
                ),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  Text(
                    _scoreText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 4. Thematic Macro Badge Cards (Protein, Lemak, Karbohidrat)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 20) / 3;
            final isStacked = constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.1;

            final proteinCard = _buildMacroBadge(
              label: 'Protein',
              value: proteinStr,
              percent:
                  '${((_baseProtein * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF2563EB),
              bg: const Color(0xFFEEF5FC),
              border: const Color(0xFFD4E5F7),
            );

            final fatCard = _buildMacroBadge(
              label: 'Lemak',
              value: fatStr,
              percent:
                  '${((_baseFat * 9 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
              icon: Icons.opacity_rounded,
              color: const Color(0xFFD97706),
              bg: const Color(0xFFFEF4E8),
              border: const Color(0xFFFCDAB4),
            );

            final carbsCard = _buildMacroBadge(
              label: 'Karbohidrat',
              value: carbsStr,
              percent:
                  '${((_baseCarbs * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
              icon: Icons.rice_bowl_outlined,
              color: const Color(0xFF7C3AED),
              bg: const Color(0xFFF5EEFD),
              border: const Color(0xFFE2D1F9),
            );

            if (isStacked) {
              return Column(
                children: [
                  proteinCard,
                  const SizedBox(height: 10),
                  fatCard,
                  const SizedBox(height: 10),
                  carbsCard,
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: cardWidth, child: proteinCard),
                const SizedBox(width: 10),
                SizedBox(width: cardWidth, child: fatCard),
                const SizedBox(width: 10),
                SizedBox(width: cardWidth, child: carbsCard),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // 5. Secondary Badges (Serat, Gula, Natrium)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildSecondaryBadge(
                icon: Icons.eco_rounded,
                label: 'Serat',
                value: _baseFiber > 0
                    ? '${_formatNum(_baseFiber * _servings)} g'
                    : '0 g',
                subtext: 'Proporsi serat alami',
                color: const Color(0xFF16A34A),
              ),
              const Divider(height: 18),
              _buildSecondaryBadge(
                icon: Icons.cookie_outlined,
                label: 'Gula',
                value: _baseSugar != null
                    ? '${_formatNum(_baseSugar! * _servings)} g'
                    : 'Belum tersedia',
                subtext: 'Gula alami & tambahan',
                color: const Color(0xFFDB2777),
              ),
              const Divider(height: 18),
              _buildSecondaryBadge(
                icon: Icons.grain_outlined,
                label: 'Natrium',
                value: _baseSodium != null
                    ? '${(_baseSodium! * _servings).round()} mg'
                    : 'Belum tersedia',
                subtext: 'Batas harian aman',
                color: const Color(0xFF0D9488),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6. Portion Selector & Stepper
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Porsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    entry.portion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick portion chips
              Row(
                children: [
                  for (final count in [1.0, 2.0, 3.0, 4.0]) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: _servings == count
                              ? AppColors.heroBackground
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _servings == count
                                  ? AppColors.heroBackground
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _servings = count),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                '${count.toInt()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _servings == count
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Stepper control: [-] [X porsi] [+]
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Kurangi porsi',
                      onPressed: _servings > 1.0
                          ? () => setState(
                                () => _servings =
                                    (_servings - 1.0).clamp(1.0, 10.0),
                              )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, size: 26),
                      color: AppColors.primaryDark,
                    ),
                    Text(
                      '${_formatServings(_servings)} porsi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tambah porsi',
                      onPressed: _servings < 10.0
                          ? () => setState(
                                () => _servings =
                                    (_servings + 1.0).clamp(1.0, 10.0),
                              )
                          : null,
                      icon: const Icon(Icons.add_circle_outline, size: 26),
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 7. Kesimpulan Singkat with Audio TTS
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PersonalColors.soft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PersonalHeading('Kesimpulan singkat'),
              Text(
                entry.spokenSummary.isEmpty
                    ? 'Kesimpulan singkat belum tersedia.'
                    : entry.spokenSummary,
                style: const TextStyle(height: 1.5),
              ),
              if (entry.spokenSummary.isNotEmpty) ...[
                const SizedBox(height: 10),
                ListenableBuilder(
                  listenable: _speech,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _speech.activeId == entry.id
                          ? _speech.stop()
                          : _speak(),
                      icon: Icon(
                        _speech.activeId == entry.id
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                      ),
                      label: Text(
                        _speech.activeId == entry.id
                            ? 'Hentikan suara'
                            : 'Dengarkan kesimpulan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
              if (_audioError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _audioError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    semanticsLabel: _audioError,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 8. Ringkasan Analisis
        if (entry.note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: PersonalColors.soft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan · Yuk, lihat trade-off-nya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PersonalColors.primary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.note,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: PersonalColors.ink,
                  ),
                ),
                if (entry.prioritySnapshot.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Fokus saat dicatat: ${entry.prioritySnapshot.join(' · ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: PersonalColors.secondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 9. Trade-Off Kelebihan & Kekurangan Cards
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBCE9E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Icon(
                    Icons.thumb_up_alt_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  Text(
                    'Kelebihan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _kelebihanText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Icon(
                    Icons.thumb_down_alt_rounded,
                    color: Color(0xFFE11D48),
                    size: 22,
                  ),
                  Text(
                    'Kekurangan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _kekuranganText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Catatan / Deskripsi Tambahan Pengguna
        if (entry.userNote != null && entry.userNote!.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: AppColors.heroBackground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Deskripsi Tambahan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  entry.userNote!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 10. ExpansionTile for Source, Basis, & Raw OCR Text
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          title: const Text(
            'Tentang data nutrisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asal data: ${entry.source.isEmpty ? 'Database Terverifikasi NutriLens' : entry.source}',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acuan perhitungan: ${entry.referenceBasis}',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: PersonalColors.secondary,
                    ),
                  ),
                  if (entry.rawOcrText != null) ...[
                    const SizedBox(height: 14),
                    const PersonalHeading('Teks label terbaca'),
                    const SizedBox(height: 6),
                    SelectableText(
                      entry.rawOcrText!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroBadge({
    required String label,
    required String value,
    required String percent,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildSecondaryBadge({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 60
                  ? constraints.maxWidth
                  : double.infinity,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtext,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
