import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/scan_history_entry.dart';
import '../../../services/summary_speech.dart';
import '../../scanner/widgets/analysis_content.dart';
import '../../../shared/widgets/personal_page.dart';

String historyDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String historyDay(DateTime date, DateTime now) => DateUtils.isSameDay(date, now)
    ? 'Hari ini · ${historyDate(date)}'
    : DateUtils.isSameDay(date, DateTime(now.year, now.month, now.day - 1))
    ? 'Kemarin · ${historyDate(date)}'
    : historyDate(date);

String nutrientText(double? value, String unit) {
  if (value == null) return 'Belum tersedia';
  final number = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString().replaceAll('.', ',');
  return '$number $unit';
}

String _formatNum(double value) =>
    (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(1))
        .replaceAll('.', ',');

String _formatServings(double s) =>
    (s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1))
        .replaceAll('.', ',');

/// Uses the captured local file when available. Missing files have a stable fallback.
class HistoryPhoto extends StatelessWidget {
  const HistoryPhoto({
    required this.entry,
    this.height = 96,
    this.width = 96,
    this.borderRadius = 16,
    super.key,
  });
  final ScanHistoryEntry entry;
  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        Container(
          color: PersonalColors.soft,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: PersonalColors.secondary,
          ),
        );
    final Widget photo;
    if (entry.photoPath != null) {
      photo = Image.file(
        File(entry.photoPath!),
        fit: BoxFit.cover,
        errorBuilder: fallback,
      );
    } else if (entry.photoAsset != null) {
      photo = Image.asset(
        entry.photoAsset!,
        fit: BoxFit.cover,
        errorBuilder: fallback,
      );
    } else {
      photo = fallback(context, StateError('No photo'), null);
    }
    return Semantics(
      label: 'Foto ${entry.name}',
      image: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(width: width, height: height, child: photo),
        ),
      ),
    );
  }
}

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({required this.entry, super.key});
  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border, width: 1.2),
    ),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (context) => HistoryEntryDetail(entry: entry),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HistoryPhoto(
                  entry: entry,
                  width: 84,
                  height: 84,
                  borderRadius: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${entry.savedAt.hour.toString().padLeft(2, '0')}:${entry.savedAt.minute.toString().padLeft(2, '0')} · ${entry.portion}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: PersonalColors.secondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                entry.note,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: PersonalColors.ink,
                  fontFamily: 'Inter',
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Lihat analisis lengkap',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PersonalColors.primary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: PersonalColors.primary,
                    ),
                  ],
                ),
                if (entry.spokenSummary.isNotEmpty)
                  ListenableBuilder(
                    listenable: SummarySpeech.shared,
                    builder: (context, _) {
                      final isPlaying =
                          SummarySpeech.shared.activeId == entry.id;
                      return TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          size: 18,
                          color: PersonalColors.primary,
                        ),
                        label: Text(
                          isPlaying ? 'Hentikan' : 'Dengarkan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PersonalColors.primary,
                          ),
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await SummarySpeech.shared.stop();
                          } else {
                            try {
                              await SummarySpeech.shared.speak(
                                entry.id,
                                entry.spokenSummary,
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error is StateError
                                          ? error.message
                                          : 'Suara belum tersedia di perangkat.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class HistoryEntryDetail extends StatefulWidget {
  const HistoryEntryDetail({required this.entry, super.key});
  final ScanHistoryEntry entry;

  @override
  State<HistoryEntryDetail> createState() => _HistoryEntryDetailState();
}

class _HistoryEntryDetailState extends State<HistoryEntryDetail> {
  double _servings = 1.0;

  double get _baseCalories => widget.entry.energyKcal ?? 0.0;
  double get _baseProtein => widget.entry.proteinG ?? 0.0;
  double? get _baseSugar => widget.entry.sugarG;
  double? get _baseSodium => widget.entry.sodiumMg;

  double get _baseFat {
    if (widget.entry.name.toLowerCase().contains('yogurt')) return 3.5;
    if (widget.entry.name.toLowerCase().contains('nasi')) return 12.0;
    if (widget.entry.name.toLowerCase().contains('teh')) return 0.0;
    return (_baseCalories * 0.25) / 9.0;
  }

  double get _baseCarbs {
    if (widget.entry.name.toLowerCase().contains('yogurt')) return 15.0;
    if (widget.entry.name.toLowerCase().contains('nasi')) return 54.0;
    if (widget.entry.name.toLowerCase().contains('teh')) return 0.0;
    return (_baseCalories * 0.5) / 4.0;
  }

  double get _baseFiber {
    if (widget.entry.name.toLowerCase().contains('nasi')) return 4.8;
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
    if (lower.contains('teh')) {
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
    if (lower.contains('teh')) {
      return 'Tidak menyumbang asupan makronutrisi penting seperti protein atau serat. Bukan pengganti makanan utama.';
    }
    return 'Perhatikan variasi konsumsi harian dan pastikan asupan mikronutrisi tetap tercukupi.';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.entry.isIllustration) {
      return FractionallySizedBox(
        heightFactor: .92,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: AnalysisContent(entry: widget.entry),
        ),
      );
    }
    return _preview(context);
  }

  // Legacy visual fixtures remain isolated from real saved results.
  Widget _preview(BuildContext context) => FractionallySizedBox(
    heightFactor: .92,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Photo Header
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 220,
                  color: AppColors.background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HistoryPhoto(
                        entry: widget.entry,
                        width: double.infinity,
                        height: 220,
                        borderRadius: 24,
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
                                widget.entry.packaged
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

              // Title
              Text(
                widget.entry.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${historyDate(widget.entry.savedAt)} · ${widget.entry.portion}',
                style: const TextStyle(
                  fontSize: 14,
                  color: PersonalColors.secondary,
                ),
              ),
              const SizedBox(height: 12),

              // Calorie & Health Score Banner
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
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

              // Thematic Macro Badge Cards (Protein, Lemak, Karbohidrat)
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 20) / 3;
                  final isStacked = constraints.maxWidth < 290;

                  final proteinStr = _baseProtein > 0
                      ? '${_formatNum(_baseProtein * _servings)} g'
                      : (widget.entry.proteinG == 0 ? '0 g' : 'Belum tersedia');

                  final fatStr = _baseFat > 0
                      ? '${_formatNum(_baseFat * _servings)} g'
                      : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');

                  final carbsStr = _baseCarbs > 0
                      ? '${_formatNum(_baseCarbs * _servings)} g'
                      : (_baseCalories == 0 ? '0 g' : 'Belum tersedia');

                  if (isStacked) {
                    return Column(
                      children: [
                        _buildMacroBadge(
                          label: 'Protein',
                          value: proteinStr,
                          percent: '${((_baseProtein * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFEEF5FC),
                          border: const Color(0xFFD4E5F7),
                        ),
                        const SizedBox(height: 10),
                        _buildMacroBadge(
                          label: 'Lemak',
                          value: fatStr,
                          percent: '${((_baseFat * 9 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.opacity_rounded,
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF4E8),
                          border: const Color(0xFFFCDAB4),
                        ),
                        const SizedBox(height: 10),
                        _buildMacroBadge(
                          label: 'Karbohidrat',
                          value: carbsStr,
                          percent: '${((_baseCarbs * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.rice_bowl_outlined,
                          color: const Color(0xFF7C3AED),
                          bg: const Color(0xFFF5EEFD),
                          border: const Color(0xFFE2D1F9),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildMacroBadge(
                          label: 'Protein',
                          value: proteinStr,
                          percent: '${((_baseProtein * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFEEF5FC),
                          border: const Color(0xFFD4E5F7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMacroBadge(
                          label: 'Lemak',
                          value: fatStr,
                          percent: '${((_baseFat * 9 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.opacity_rounded,
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF4E8),
                          border: const Color(0xFFFCDAB4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMacroBadge(
                          label: 'Karbohidrat',
                          value: carbsStr,
                          percent: '${((_baseCarbs * 4 / (_baseCalories > 0 ? _baseCalories : 1)) * 100).clamp(5, 95).round()}%',
                          icon: Icons.rice_bowl_outlined,
                          color: const Color(0xFF7C3AED),
                          bg: const Color(0xFFF5EEFD),
                          border: const Color(0xFFE2D1F9),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Secondary Badges (Serat, Gula, Natrium)
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

              // Portion Selector (Porsi) with Quick Units & Stepper
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
                          widget.entry.portion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick portion chips: 1, 2, 3, 4
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Kurangi porsi',
                            onPressed: _servings > 1.0
                                ? () => setState(
                                      () => _servings = (_servings - 1.0)
                                          .clamp(1.0, 10.0),
                                    )
                                : null,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 26,
                            ),
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
                                      () => _servings = (_servings + 1.0)
                                          .clamp(1.0, 10.0),
                                    )
                                : null,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 26,
                            ),
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ringkasan & Trade-off Nutrisi
              if (widget.entry.note.isNotEmpty) ...[
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
                        widget.entry.note,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: PersonalColors.ink,
                        ),
                      ),
                      if (widget.entry.prioritySnapshot.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Fokus saat dicatat: ${widget.entry.prioritySnapshot.join(' · ')}',
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
                const SizedBox(height: 16),
              ],

              // Trade-Off Kelebihan & Kekurangan Cards
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

              // ExpansionTile for Source & Reference Basis
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
                          'Asal data: ${widget.entry.source.isEmpty ? 'Database Terverifikasi NutriLens' : widget.entry.source}',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acuan perhitungan: ${widget.entry.referenceBasis}',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: PersonalColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Angka di atas berlaku untuk porsi yang kamu catat.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: PersonalColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
  }) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
