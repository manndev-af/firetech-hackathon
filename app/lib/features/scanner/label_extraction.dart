/// Conservative OCR suggestions, not verified nutrition or portion calculations.
const labelNutrients = <({String label, String unit, String pattern})>[
  (
    label: 'Energi',
    unit: 'kkal',
    pattern: r'(?:energi(?: total)?|(?:total )?(?:energy|calories))',
  ),
  (label: 'Protein', unit: 'g', pattern: r'protein'),
  (
    label: 'Gula',
    unit: 'g',
    pattern: r'(?:gula(?: total)?|total sugars?|sugars?)',
  ),
  (
    label: 'Natrium',
    unit: 'mg',
    pattern: r'(?:garam\s*\(natrium\)|salt\s*\(sodium\)|natrium|sodium)',
  ),
  (label: 'Lemak total', unit: 'g', pattern: r'(?:lemak\s*total|total fat)'),
  (
    label: 'Lemak jenuh',
    unit: 'g',
    pattern: r'(?:lemak\s*jenuh|saturated fat)',
  ),
  (
    label: 'Karbohidrat',
    unit: 'g',
    pattern: r'(?:karbohidrat(?: total)?|total carbohydrate|carbohydrate)',
  ),
  (
    label: 'Serat',
    unit: 'g',
    pattern: r'(?:serat(?: pangan)?|dietary fib(?:er|re)|fib(?:er|re))',
  ),
];

class LabelExtraction {
  const LabelExtraction({required this.nutrients, required this.servingText});
  final Map<String, double?> nutrients;
  final String? servingText;
}

LabelExtraction extractLabel(String text) {
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final values = <String, double?>{};
  for (final field in labelNutrients) {
    final unit = field.unit == 'kkal'
        ? r'(?:kkal|kcal)(?:\s*/\s*(?:kkal|kcal))?'
        : field.unit;
    final heading = RegExp(
      '^${field.pattern}(?:\\s*/\\s*${field.pattern})?\\s*:?\\s*',
      caseSensitive: false,
    );
    // Reject multiple columns, negative/approximate amounts, unknown units and
    // thousands separators rather than guessing which printed value applies.
    final amount = RegExp(
      '^(\\d+(?:[.,]\\d{1,2})?)\\s*$unit(?:\\s+\\d+(?:[.,]\\d+)?\\s*%)?\\s*\$',
      caseSensitive: false,
    );
    final candidates = <double>[];
    var occurrences = 0;
    for (var i = 0; i < lines.length; i++) {
      if (field.label == 'Energi' &&
          RegExp(
            r'energi\s*dari|energy\s*from|AKG|daily|kebutuhan',
            caseSensitive: false,
          ).hasMatch(lines[i])) {
        continue;
      }
      final match = heading.firstMatch(lines[i]);
      if (match == null) continue;
      occurrences++;
      var tail = lines[i].substring(match.end).trim();
      if (tail.isEmpty && i + 1 < lines.length) tail = lines[i + 1];
      final found = amount.firstMatch(tail);
      if (found != null) {
        final value = double.tryParse(found.group(1)!.replaceAll(',', '.'));
        if (value != null && value.isFinite) candidates.add(value);
      }
    }
    values[field.label] = occurrences == 1 && candidates.length == 1
        ? candidates.single
        : null;
  }
  final servings = lines
      .where(
        (line) => RegExp(
          r'^(takaran saji|serving size)\b',
          caseSensitive: false,
        ).hasMatch(line),
      )
      .toList();
  return LabelExtraction(
    nutrients: values,
    servingText: servings.length == 1 ? servings.single : null,
  );
}
