import 'package:flutter/material.dart';

import '../../models/history_preview_data.dart';
import '../../models/scan_history_entry.dart';
import '../../models/scan_draft.dart';
import '../../shared/widgets/personal_page.dart';
import 'widgets/history_entry_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    this.entries = const [],
    this.preview = false,
    this.now,
    this.onScan,
    this.drafts = const [],
    this.onResume,
    super.key,
  });
  final List<ScanHistoryEntry> entries;
  final bool preview;
  final DateTime? now;
  final VoidCallback? onScan;
  final List<ScanDraft> drafts;
  final ValueChanged<ScanDraft>? onResume;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final records =
        (preview
              ? historyPreviewData(today)
              : entries.where((entry) => !entry.isIllustration).toList())
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    // Only show drafts that have NOT yet been saved as a completed history entry.
    final completedIds = {for (final e in records) e.id};
    final pendingDrafts = drafts
        .where((d) => !completedIds.contains(d.id))
        .toList();

    return PersonalPage(
      title: 'Riwayat',
      subtitle: 'Makananmu, dalam satu catatan.',
      children: [
        if (pendingDrafts.isNotEmpty) ...[
          const PersonalHeading('Menunggu analisis'),
          for (final draft in pendingDrafts.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PersonalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      draft.label ? 'Label produk' : 'Foto makanan',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${historyDate(draft.createdAt)} · Tersimpan di perangkat',
                    ),
                    TextButton(
                      onPressed: onResume == null
                          ? null
                          : () => onResume!(draft),
                      child: const Text('Lanjutkan analisis'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
        if (records.isEmpty && pendingDrafts.isEmpty) ...[
          PersonalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 36,
                  color: PersonalColors.primary,
                ),
                const SizedBox(height: 20),
                const PersonalHeading('Belum ada hasil tersimpan'),
                const Text(
                  'Simpan hasil analisis untuk melihat kembali foto dan ringkasan makananmu.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      onScan ??
                      () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kamera makanan belum tersedia.'),
                        ),
                      ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Mulai pindai'),
                ),
              ],
            ),
          ),
        ] else
          for (var i = 0; i < records.length; i++) ...[
            if (i == 0 ||
                !DateUtils.isSameDay(
                  records[i].savedAt,
                  records[i - 1].savedAt,
                ))
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: PersonalHeading(historyDay(records[i].savedAt, today)),
              ),
            HistoryEntryCard(entry: records[i]),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}
