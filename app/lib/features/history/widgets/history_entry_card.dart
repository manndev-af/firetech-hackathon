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
        showDragHandle: false,
        backgroundColor: AppColors.background,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            if (entry.userNote != null && entry.userNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.userNote!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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

class HistoryEntryDetail extends StatelessWidget {
  const HistoryEntryDetail({required this.entry, super.key});
  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Fixed Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top drag pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: AppColors.heroBackground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rincian Riwayat Makanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Informasi gizi & analisis trade-off',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                child: AnalysisContent(entry: entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

