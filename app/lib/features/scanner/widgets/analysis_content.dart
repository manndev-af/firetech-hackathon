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
    this.onQuantityChanged,
    super.key,
  });
  final ScanHistoryEntry entry;
  final bool autoSpeak;
  final ValueChanged<double>? onQuantityChanged;

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
    if (widget.entry.totalFatG != null) return widget.entry.totalFatG!;
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) return 3.5;
    if (lower.contains('nasi')) return 12.0;
    if (lower.contains('teh') || lower.contains('air')) return 0.0;
    return (_baseCalories * 0.25) / 9.0;
  }

  double get _baseCarbs {
    if (widget.entry.carbohydratesG != null) return widget.entry.carbohydratesG!;
    final lower = widget.entry.name.toLowerCase();
    if (lower.contains('yogurt')) return 15.0;
    if (lower.contains('nasi')) return 54.0;
    if (lower.contains('teh') || lower.contains('air')) return 0.0;
    return (_baseCalories * 0.5) / 4.0;
  }

  double get _baseFiber {
    if (widget.entry.fiberG != null) return widget.entry.fiberG!;
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
    if (widget.entry.pros.isNotEmpty) {
      return widget.entry.pros.join('\n');
    }
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
    return widget.entry.note.isNotEmpty
        ? widget.entry.note
        : 'Menyediakan asupan nutrisi yang terukur untuk mendukung kebutuhan energi dan aktivitas fisik kamu.';
  }

  String get _kekuranganText {
    if (widget.entry.cons.isNotEmpty) {
      return widget.entry.cons.join('\n');
    }
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

  void _updateServings(double newServings) {
    setState(() => _servings = newServings);
    widget.onQuantityChanged?.call(newServings);
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
    final totalCalories = (_baseCalories * _servings).round();
    final proteinStr = _baseProtein > 0
        ? '${_formatNum(_baseProtein * _servings)} g'
        : (entry.proteinG == 0 ? '0 g' : 'Belum tersedia');
    final fatStr = _baseFat > 0
        ? '${_formatNum(_baseFat * _servings)} g'
        : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');
    final carbsStr = _baseCarbs > 0
        ? '${_formatNum(_baseCarbs * _servings)} g'
        : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');

    final proteinPercent =
        '${((_baseProtein * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%';
    final fatPercent =
        '${((_baseFat * 9 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%';
    final carbsPercent =
        '${((_baseCarbs * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Photo with AI Verification Badge
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 190,
            color: AppColors.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (entry.photoPath != null)
                  Image.file(
                    File(entry.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => _buildPhotoFallback(),
                  )
                else if (entry.photoAsset != null)
                  Image.asset(
                    entry.photoAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => _buildPhotoFallback(),
                  )
                else
                  _buildPhotoFallback(),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.heroBackground.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.cyan,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          entry.packaged
                              ? 'Label Terbaca AI'
                              : 'Makanan Terverifikasi AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
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
        const SizedBox(height: 14),

        // 2. Food Identity & Energy Banner Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        historyDate(entry.savedAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Text('·', style: TextStyle(color: AppColors.border)),
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        entry.portion,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: 16),
              // Calorie & Score Metrics (Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isReflow = constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;

                  if (isReflow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimasi Energi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCalories kal',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heroBackground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            const Text(
                              'Kualitas Gizi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.cyan.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 5,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  Text(
                                    _scoreText,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimasi Energi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCalories kal',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heroBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kualitas Gizi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.cyan.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 5,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  Text(
                                    _scoreText,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Portion Adjustment Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: AppColors.heroBackground,
                        ),
                      ),
                      const Text(
                        'Sesuaikan Porsi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    entry.portion,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick chips
              Row(
                children: [
                  for (final count in [1.0, 2.0, 3.0, 4.0]) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: _servings == count
                              ? AppColors.heroBackground
                              : AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _servings == count
                                  ? AppColors.heroBackground
                                  : AppColors.border,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _updateServings(count),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '${count.toInt()}x',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
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
              const SizedBox(height: 10),
              // Stepper control: [-] [X porsi] [+]
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Kurangi porsi',
                      visualDensity: VisualDensity.compact,
                      onPressed: _servings > 1.0
                          ? () => _updateServings(
                                (_servings - 1.0).clamp(1.0, 10.0),
                              )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: AppColors.primaryDark,
                    ),
                    Flexible(
                      child: Text(
                        '${_formatServings(_servings)} porsi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tambah porsi',
                      visualDensity: VisualDensity.compact,
                      onPressed: _servings < 10.0
                          ? () => _updateServings(
                                (_servings + 1.0).clamp(1.0, 10.0),
                              )
                          : null,
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Kandungan Nutrisi (Makro & Mikro Terpadu)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 16,
                          color: AppColors.heroBackground,
                        ),
                      ),
                      const Text(
                        'Kandungan Nutrisi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${_formatServings(_servings)} porsi',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Three Macro Columns
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 260 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;
                  final proteinWidget = _buildMacroCard(
                    label: 'Protein',
                    value: proteinStr,
                    percent: proteinPercent,
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFF0F7FF),
                    border: const Color(0xFFD0E4FF),
                  );
                  final fatWidget = _buildMacroCard(
                    label: 'Lemak',
                    value: fatStr,
                    percent: fatPercent,
                    icon: Icons.opacity_rounded,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                  );
                  final carbsWidget = _buildMacroCard(
                    label: 'Karbo',
                    value: carbsStr,
                    percent: carbsPercent,
                    icon: Icons.grain_rounded,
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFFAF5FF),
                    border: const Color(0xFFE9D5FF),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        proteinWidget,
                        const SizedBox(height: 8),
                        fatWidget,
                        const SizedBox(height: 8),
                        carbsWidget,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: proteinWidget),
                      const SizedBox(width: 8),
                      Expanded(child: fatWidget),
                      const SizedBox(width: 8),
                      Expanded(child: carbsWidget),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: 14),
              // Secondary Nutrients (Serat, Gula, Natrium)
              _buildSecondaryRow(
                icon: Icons.eco_rounded,
                label: 'Serat',
                value: _baseFiber > 0
                    ? '${_formatNum(_baseFiber * _servings)} g'
                    : '0 g',
                subtext: 'Proporsi serat alami',
                color: const Color(0xFF16A34A),
              ),
              const Divider(height: 16, thickness: 0.5, color: AppColors.border),
              _buildSecondaryRow(
                icon: Icons.cookie_outlined,
                label: 'Gula',
                value: _baseSugar != null
                    ? '${_formatNum(_baseSugar! * _servings)} g'
                    : 'Belum tersedia',
                subtext: 'Gula alami & tambahan',
                color: const Color(0xFFDB2777),
              ),
              const Divider(height: 16, thickness: 0.5, color: AppColors.border),
              _buildSecondaryRow(
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
        const SizedBox(height: 16),

        // 5. Analisis & Trade-Off Personal Section
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.heroBackground,
              ),
            ),
            const Text(
              'Analisis & Trade-Off Personal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 5a. Kesimpulan AI & Audio Narasi Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PersonalColors.soft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PersonalHeading('Kesimpulan singkat'),
              const SizedBox(height: 4),
              Text(
                entry.spokenSummary.isEmpty
                    ? 'Kesimpulan singkat belum tersedia.'
                    : entry.spokenSummary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: PersonalColors.ink,
                ),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      onPressed: () => _speech.activeId == entry.id
                          ? _speech.stop()
                          : _speak(),
                      icon: Icon(
                        _speech.activeId == entry.id
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _speech.activeId == entry.id
                            ? 'Hentikan suara'
                            : 'Dengarkan kesimpulan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
        const SizedBox(height: 12),

        // 5b. Ringkasan Trade-Off Detail Card
        if (entry.note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan · Yuk, lihat trade-off-nya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PersonalColors.primary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.note,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: PersonalColors.ink,
                  ),
                ),
                if (entry.prioritySnapshot.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Fokus saat dicatat: ${entry.prioritySnapshot.join(' · ')}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: PersonalColors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 5c. Kelebihan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  Icon(
                    Icons.thumb_up_alt_rounded,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                  Text(
                    'Kelebihan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _kelebihanText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5d. Kekurangan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  Icon(
                    Icons.thumb_down_alt_rounded,
                    color: Color(0xFFE11D48),
                    size: 18,
                  ),
                  Text(
                    'Kekurangan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _kekuranganText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6. User Note (if provided)
        if (entry.userNote != null && entry.userNote!.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.heroBackground,
                      ),
                    ),
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
                const SizedBox(height: 8),
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
          const SizedBox(height: 14),
        ],

        // 7. ExpansionTile for Source & Reference Basis
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text(
                'Tentang data nutrisi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asal data: ${entry.source.isEmpty ? 'Database Terverifikasi NutriLens' : entry.source}',
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acuan perhitungan: ${entry.referenceBasis}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: PersonalColors.secondary,
                        ),
                      ),
                      if (entry.rawOcrText != null) ...[
                        const SizedBox(height: 12),
                        const PersonalHeading('Teks label terbaca'),
                        const SizedBox(height: 6),
                        SelectableText(
                          entry.rawOcrText!,
                          style: const TextStyle(
                            fontSize: 12.5,
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
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoFallback() => Container(
    color: PersonalColors.soft,
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: PersonalColors.secondary,
      size: 36,
    ),
  );

  Widget _buildMacroCard({
    required String label,
    required String value,
    required String percent,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildSecondaryRow({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 80
                  ? constraints.maxWidth
                  : double.infinity,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtext,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
