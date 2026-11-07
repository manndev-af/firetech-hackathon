import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/scan_history_entry.dart';
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
    super.key,
  });
  final ScanHistoryEntry entry;
  final double height;
  final double width;

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
          borderRadius: BorderRadius.circular(16),
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
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: PersonalColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
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
                HistoryPhoto(entry: entry, width: 80, height: 88),
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
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${entry.savedAt.hour.toString().padLeft(2, '0')}:${entry.savedAt.minute.toString().padLeft(2, '0')} \u00b7 ${entry.portion}',
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
              const SizedBox(height: 16),
              Text(
                entry.note,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: PersonalColors.ink,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Lihat analisis',
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
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HistoryPhoto(entry: entry, width: double.infinity, height: 180),
          const SizedBox(height: 20),
          Text(
            entry.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${historyDate(entry.savedAt)} \u00b7 ${entry.portion}',
            style: const TextStyle(
              fontSize: 14,
              color: PersonalColors.secondary,
            ),
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PersonalColors.soft,
                borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(fontSize: 14, height: 1.5),
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
          ],
          const SizedBox(height: 24),
          const PersonalHeading('Nutrisi dalam porsi ini'),
          for (final nutrient in [
            (label: 'Energi', value: nutrientText(entry.energyKcal, 'kkal')),
            (label: 'Protein', value: nutrientText(entry.proteinG, 'g')),
            (label: 'Gula', value: nutrientText(entry.sugarG, 'g')),
            (label: 'Natrium', value: nutrientText(entry.sodiumMg, 'mg')),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(nutrient.label, style: const TextStyle(fontSize: 14)),
                  Text(
                    nutrient.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: PersonalColors.border),
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
                      'Asal data: ${entry.source.isEmpty ? 'Belum dicantumkan' : entry.source}',
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
  );
}
