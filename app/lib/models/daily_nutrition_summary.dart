/// Display data supplied by the future confirmed food-history integration.
/// Totals must already use the logged portions; this model does not estimate them.
class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.recordCount,
    this.sugarG,
    this.proteinG,
    this.energyKcal,
    this.sugarComplete = true,
    this.proteinComplete = true,
    this.energyComplete = true,
  }) : assert(recordCount > 0),
       assert(sugarG == null || (sugarG >= 0 && sugarG < double.infinity)),
       assert(
         proteinG == null || (proteinG >= 0 && proteinG < double.infinity),
       ),
       assert(
         energyKcal == null ||
             (energyKcal >= 0 && energyKcal < double.infinity),
       );

  final int recordCount;
  final double? sugarG;
  final double? proteinG;
  final double? energyKcal;
  final bool sugarComplete;
  final bool proteinComplete;
  final bool energyComplete;

  List<String> get incompleteNutrients => [
    if (sugarG == null || !sugarComplete) 'gula',
    if (proteinG == null || !proteinComplete) 'protein',
    if (energyKcal == null || !energyComplete) 'energi',
  ];

  static DailyNutritionSummary? fromBackend(Map<String, dynamic> data) {
    final count = (data['entryCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return null;

    final nutrients = data['nutrients'] is Map
        ? Map<String, dynamic>.from(data['nutrients'] as Map)
        : const <String, dynamic>{};

    final caloriesMap = nutrients['calories_kcal'] is Map
        ? Map<String, dynamic>.from(nutrients['calories_kcal'] as Map)
        : null;
    final proteinMap = nutrients['protein_g'] is Map
        ? Map<String, dynamic>.from(nutrients['protein_g'] as Map)
        : null;
    final sugarMap = nutrients['sugar_g'] is Map
        ? Map<String, dynamic>.from(nutrients['sugar_g'] as Map)
        : null;

    final energy = (caloriesMap?['knownTotal'] as num?)?.toDouble();
    final protein = (proteinMap?['knownTotal'] as num?)?.toDouble();
    final sugar = (sugarMap?['knownTotal'] as num?)?.toDouble();

    return DailyNutritionSummary(
      recordCount: count,
      energyKcal: energy != null && energy >= 0 ? energy : null,
      energyComplete: caloriesMap?['complete'] as bool? ?? true,
      proteinG: protein != null && protein >= 0 ? protein : null,
      proteinComplete: proteinMap?['complete'] as bool? ?? true,
      sugarG: sugar != null && sugar >= 0 ? sugar : null,
      sugarComplete: sugarMap?['complete'] as bool? ?? true,
    );
  }
}
