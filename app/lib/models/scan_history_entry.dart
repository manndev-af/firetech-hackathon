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
    this.rawOcrText,
    this.spokenSummary = '',
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
  final String? rawOcrText;
  final String spokenSummary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'packaged': packaged,
    'portion': portion,
    'source': source,
    'referenceBasis': referenceBasis,
    'energyKcal': energyKcal,
    'proteinG': proteinG,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
    'prioritySnapshot': prioritySnapshot,
    'note': note,
    'isIllustration': isIllustration,
    'photoPath': photoPath,
    'rawOcrText': rawOcrText,
    'spokenSummary': spokenSummary,
  };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        packaged: json['packaged'] as bool,
        portion: json['portion'] as String,
        source: json['source'] as String,
        referenceBasis: json['referenceBasis'] as String,
        energyKcal: (json['energyKcal'] as num?)?.toDouble(),
        proteinG: (json['proteinG'] as num?)?.toDouble(),
        sugarG: (json['sugarG'] as num?)?.toDouble(),
        sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
        prioritySnapshot: List<String>.from(
          json['prioritySnapshot'] as List? ?? [],
        ),
        note: json['note'] as String? ?? '',
        isIllustration: json['isIllustration'] as bool? ?? false,
        photoPath: json['photoPath'] as String?,
        rawOcrText: json['rawOcrText'] as String?,
        spokenSummary: json['spokenSummary'] as String? ?? '',
      );
}
