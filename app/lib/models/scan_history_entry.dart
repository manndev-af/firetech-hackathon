/// Display-only snapshot. Nutrient calculations belong to the backend.
class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.packaged,
    required this.portion,
    required this.source,
    required this.referenceBasis,
    this.energyKcal,
    this.proteinG,
    this.sugarG,
    this.sodiumMg,
    this.prioritySnapshot = const [],
    this.note = '',
    this.isIllustration = false,
    this.photoPath,
    this.photoAsset,
  });

  final String id;
  final String name;
  final DateTime savedAt;
  final bool packaged;
  final String portion;
  final String source;
  final String referenceBasis;
  final double? energyKcal;
  final double? proteinG;
  final double? sugarG;
  final double? sodiumMg;
  final List<String> prioritySnapshot;
  final String note;
  final bool isIllustration;

  /// Local camera capture, retained by the future history integration.
  final String? photoPath;

  /// Bundled photo used only by the separate design preview.
  final String? photoAsset;
}
