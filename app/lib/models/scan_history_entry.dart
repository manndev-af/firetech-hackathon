/// Catatan riwayat konsumsi makanan/label nutrisi.
/// Mendukung 8 metrik nutrisi, insight personal pros/cons, dan kalkulasi porsi backend.
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
    this.totalFatG,
    this.saturatedFatG,
    this.carbohydratesG,
    this.sugarG,
    this.sodiumMg,
    this.fiberG,
    this.pros = const [],
    this.cons = const [],
    this.quantity = 1.0,
    this.baseQuantity = 1.0,
    this.provenance,
    this.ttsSummarySource,
    this.prioritySnapshot = const [],
    this.note = '',
    this.userNote,
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
  final double? totalFatG;
  final double? saturatedFatG;
  final double? carbohydratesG;
  final double? sugarG;
  final double? sodiumMg;
  final double? fiberG;
  final List<String> pros;
  final List<String> cons;
  final double quantity;
  final double? baseQuantity;
  final String? provenance;
  final String? ttsSummarySource;
  final List<String> prioritySnapshot;
  final String note;
  final String? userNote;
  final bool isIllustration;

  /// Local camera capture, retained by the future history integration.
  final String? photoPath;

  /// Bundled photo used only by the separate design preview.
  final String? photoAsset;
  final String? rawOcrText;
  final String spokenSummary;

  ScanHistoryEntry copyWith({
    String? id,
    String? name,
    DateTime? savedAt,
    bool? packaged,
    String? portion,
    String? source,
    String? referenceBasis,
    double? energyKcal,
    double? proteinG,
    double? totalFatG,
    double? saturatedFatG,
    double? carbohydratesG,
    double? sugarG,
    double? sodiumMg,
    double? fiberG,
    List<String>? pros,
    List<String>? cons,
    double? quantity,
    double? baseQuantity,
    String? provenance,
    String? ttsSummarySource,
    List<String>? prioritySnapshot,
    String? note,
    String? userNote,
    bool? isIllustration,
    String? photoPath,
    String? photoAsset,
    String? rawOcrText,
    String? spokenSummary,
  }) => ScanHistoryEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    savedAt: savedAt ?? this.savedAt,
    packaged: packaged ?? this.packaged,
    portion: portion ?? this.portion,
    source: source ?? this.source,
    referenceBasis: referenceBasis ?? this.referenceBasis,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    totalFatG: totalFatG ?? this.totalFatG,
    saturatedFatG: saturatedFatG ?? this.saturatedFatG,
    carbohydratesG: carbohydratesG ?? this.carbohydratesG,
    sugarG: sugarG ?? this.sugarG,
    sodiumMg: sodiumMg ?? this.sodiumMg,
    fiberG: fiberG ?? this.fiberG,
    pros: pros ?? this.pros,
    cons: cons ?? this.cons,
    quantity: quantity ?? this.quantity,
    baseQuantity: baseQuantity ?? this.baseQuantity,
    provenance: provenance ?? this.provenance,
    ttsSummarySource: ttsSummarySource ?? this.ttsSummarySource,
    prioritySnapshot: prioritySnapshot ?? this.prioritySnapshot,
    note: note ?? this.note,
    userNote: userNote ?? this.userNote,
    isIllustration: isIllustration ?? this.isIllustration,
    photoPath: photoPath ?? this.photoPath,
    photoAsset: photoAsset ?? this.photoAsset,
    rawOcrText: rawOcrText ?? this.rawOcrText,
    spokenSummary: spokenSummary ?? this.spokenSummary,
  );

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
    'totalFatG': totalFatG,
    'saturatedFatG': saturatedFatG,
    'carbohydratesG': carbohydratesG,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
    'fiberG': fiberG,
    'pros': pros,
    'cons': cons,
    'quantity': quantity,
    'baseQuantity': baseQuantity,
    'provenance': provenance,
    'ttsSummarySource': ttsSummarySource,
    'prioritySnapshot': prioritySnapshot,
    'note': note,
    if (userNote != null) 'userNote': userNote,
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
        totalFatG: (json['totalFatG'] as num?)?.toDouble(),
        saturatedFatG: (json['saturatedFatG'] as num?)?.toDouble(),
        carbohydratesG: (json['carbohydratesG'] as num?)?.toDouble(),
        sugarG: (json['sugarG'] as num?)?.toDouble(),
        sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
        fiberG: (json['fiberG'] as num?)?.toDouble(),
        pros: List<String>.from(json['pros'] as List? ?? []),
        cons: List<String>.from(json['cons'] as List? ?? []),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        baseQuantity: (json['baseQuantity'] as num?)?.toDouble(),
        provenance: json['provenance'] as String?,
        ttsSummarySource: json['ttsSummarySource'] as String?,
        prioritySnapshot: List<String>.from(
          json['prioritySnapshot'] as List? ?? [],
        ),
        note: json['note'] as String? ?? '',
        userNote: json['userNote'] as String?,
        isIllustration: json['isIllustration'] as bool? ?? false,
        photoPath: json['photoPath'] as String?,
        rawOcrText: json['rawOcrText'] as String?,
        spokenSummary: json['spokenSummary'] as String? ?? '',
      );

  /// Factory untuk memetakan skema respons backend `entrySchema`.
  factory ScanHistoryEntry.fromBackend(
    Map<String, dynamic> data, {
    String? localPhotoPath,
    String? userNote,
    List<String> prioritySnapshot = const [],
  }) {
    final nutrients = data['nutrients'] is Map
        ? Map<String, dynamic>.from(data['nutrients'] as Map)
        : const <String, dynamic>{};

    double? parseNutrient(String key, [String? fallbackKey]) {
      final value = nutrients[key] ?? (fallbackKey != null ? nutrients[fallbackKey] : null);
      if (value == null) return null;
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Invalid nutrient: $key');
      }
      return value.toDouble();
    }

    if (data['spokenSummary'] is String && (data['spokenSummary'] as String).length > 320) {
      throw const FormatException('Invalid spoken summary');
    }
    if (data['ttsSummary'] is String && (data['ttsSummary'] as String).length > 450) {
      throw const FormatException('Invalid tts summary');
    }

    final analysis = data['analysis'] is Map
        ? Map<String, dynamic>.from(data['analysis'] as Map)
        : null;
    final portionObj = analysis?['portion'] is Map
        ? Map<String, dynamic>.from(analysis!['portion'] as Map)
        : null;

    final portionLabel = portionObj?['displayLabel'] as String? ??
        data['portion'] as String? ??
        '1 porsi';

    final referenceBasis = portionObj?['basis'] as String? ??
        data['referenceBasis'] as String? ??
        'Per sajian';

    final title = data['title'] as String? ??
        analysis?['identity'] as String? ??
        data['foodName'] as String? ??
        'Makanan';

    final prosList = data['pros'] is List
        ? List<String>.from((data['pros'] as List).map((e) => e.toString()))
        : analysis?['advantages'] is List
            ? List<String>.from((analysis!['advantages'] as List).map((e) => e.toString()))
            : <String>[];

    final consList = data['cons'] is List
        ? List<String>.from((data['cons'] as List).map((e) => e.toString()))
        : analysis?['tradeoffs'] is List
            ? List<String>.from((analysis!['tradeoffs'] as List).map((e) => e.toString()))
            : <String>[];

    final spoken = data['ttsSummary'] as String? ??
        data['spokenSummary'] as String? ??
        analysis?['ttsSummary'] as String? ??
        '';

    final effectiveNote = data['description'] as String? ??
        analysis?['evidence'] as String? ??
        data['note'] as String? ??
        data['summary'] as String? ??
        '';

    final consumedAt = data['consumedAt'] is String
        ? DateTime.tryParse(data['consumedAt'] as String) ?? DateTime.now()
        : DateTime.now();

    final isLabel = data['mode'] == 'label' || data['packaged'] == true;

    return ScanHistoryEntry(
      id: data['id'] as String? ?? '',
      name: title,
      savedAt: consumedAt,
      packaged: isLabel,
      portion: portionLabel,
      source: data['provenance'] as String? ?? (isLabel ? 'Label Informasi Nilai Gizi' : 'Estimasi AI'),
      referenceBasis: referenceBasis,
      energyKcal: parseNutrient('calories_kcal', 'energyKcal'),
      proteinG: parseNutrient('protein_g', 'proteinG'),
      totalFatG: parseNutrient('total_fat_g', 'totalFatG'),
      saturatedFatG: parseNutrient('saturated_fat_g', 'saturatedFatG'),
      carbohydratesG: parseNutrient('carbohydrates_g', 'carbohydratesG'),
      sugarG: parseNutrient('sugar_g', 'sugarG'),
      sodiumMg: parseNutrient('sodium_mg', 'sodiumMg'),
      fiberG: parseNutrient('fiber_g', 'fiberG'),
      pros: prosList,
      cons: consList,
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      baseQuantity: (data['baseQuantity'] as num?)?.toDouble(),
      provenance: data['provenance'] as String?,
      ttsSummarySource: data['ttsSummarySource'] as String?,
      prioritySnapshot: prioritySnapshot,
      note: effectiveNote,
      userNote: userNote ?? (data['userNote'] as String?),
      photoPath: localPhotoPath,
      rawOcrText: data['rawOcrText'] as String?,
      spokenSummary: spoken.trim().isNotEmpty
          ? spoken.trim()
          : 'Hasil analisis sudah tersedia. Periksa nama makanan, porsi, dan informasi nutrisinya.',
    );
  }
}
