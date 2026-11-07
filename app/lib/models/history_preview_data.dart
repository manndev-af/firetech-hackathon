import 'scan_history_entry.dart';

/// Contoh riwayat awal untuk pengujian TTS dan aksesibilitas tanpa harus memindai terlebih dahulu.
ScanHistoryEntry get sampleHistoryEntry {
  final now = DateTime.now();
  return ScanHistoryEntry(
    id: 'sample_history_yogurt',
    name: 'Yogurt Stroberi & Granola',
    savedAt: now.subtract(const Duration(hours: 6)),
    packaged: true,
    portion: '1 cup · 150 g',
    source: 'Label Informasi Nilai Gizi',
    referenceBasis: 'Per sajian 150 g',
    photoAsset: 'assets/images/history_yogurt.jpg',
    energyKcal: 140,
    proteinG: 8,
    sugarG: 12,
    sodiumMg: 70,
    prioritySnapshot: const ['Gula', 'Protein'],
    note:
        'Ada 8 g protein dan 12 g gula dalam porsi ini. Pilihan camilan dengan kalsium baik, perhatikan asupan gula tambahan.',
    spokenSummary:
        'Porsi camilan baik dengan 8 gram protein. Perhatikan 12 gram gula sesuai target harianmu.',
    userNote: 'Camilan sore setelah berolahraga',
    isIllustration: false,
  );
}

/// Fictional UI fixtures, never inserted into the user's history or summaries.
List<ScanHistoryEntry> historyPreviewData(DateTime now) => [
  ScanHistoryEntry(
    id: 'preview-yogurt',
    name: 'Yogurt stroberi',
    savedAt: DateTime(now.year, now.month, now.day, 10, 15),
    packaged: true,
    portion: '1 cup · 150 g',
    photoAsset: 'assets/images/history_yogurt.jpg',
    source: '',
    referenceBasis: 'Per sajian 150 g',
    energyKcal: 140,
    proteinG: 8,
    sugarG: 12,
    sodiumMg: 70,
    prioritySnapshot: const ['Gula', 'Protein'],
    note: 'Ada 8 g protein dan 12 g gula dalam porsi ini. Perhatikan keduanya saat memilih camilan.',
    isIllustration: true,
  ),
  ScanHistoryEntry(
    id: 'preview-rice',
    name: 'Nasi, ayam & sayur',
    savedAt: DateTime(now.year, now.month, now.day, 8, 30),
    packaged: false,
    portion: '1 porsi · 250 g',
    photoAsset: 'assets/images/history_rice.jpg',
    source: '',
    referenceBasis: 'Per 100 g; dihitung untuk 250 g',
    energyKcal: 420,
    proteinG: 24,
    sugarG: null,
    sodiumMg: null,
    prioritySnapshot: const ['Protein', 'Keseimbangan'],
    note: 'Porsi ini mengandung 24 g protein. Informasi gula dan natrium belum tersedia.',
    isIllustration: true,
  ),
  ScanHistoryEntry(
    id: 'preview-tea',
    name: 'Teh tawar',
    savedAt: DateTime(now.year, now.month, now.day - 1, 16, 0),
    packaged: false,
    portion: '1 gelas · 200 ml',
    photoAsset: 'assets/images/history_tea.jpg',
    source: '',
    referenceBasis: 'Per 100 ml; dihitung untuk 200 ml',
    energyKcal: 0,
    proteinG: 0,
    sugarG: 0,
    sodiumMg: null,
    prioritySnapshot: const ['Gula'],
    note:
        'Gula tercatat 0 g untuk satu gelas. Informasi natrium belum tersedia.',
    isIllustration: true,
  ),
];
