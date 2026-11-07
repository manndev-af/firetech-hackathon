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
}
