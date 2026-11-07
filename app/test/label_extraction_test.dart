import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/features/scanner/label_extraction.dart';

void main() {
  test(
    'sample label separates total energy, fat energy and daily reference',
    () {
      final result = extractLabel('''Takaran saji 20 g
Energi Total/Total Calories 100 kkal/kcal
Energi dari Lemak 45 kkal
Lemak Total / Total Fat 5 g
LemakJenuh 2 g
Protein 0 g
Karbohidrat Total 14 g
Gula 1 g
Garam (Natrium)/Salt (Sodium) 210 mg
Kebutuhan energi 2150 kkal''');
      expect(result.nutrients, {
        'Energi': 100,
        'Protein': 0,
        'Gula': 1,
        'Natrium': 210,
        'Lemak total': 5,
        'Lemak jenuh': 2,
        'Karbohidrat': 14,
        'Serat': null,
      });
    },
  );
  test('preserves serving, decimal amounts, zero and missing values', () {
    final result = extractLabel(
      'Takaran saji 30 g\nEnergi total 120 kkal\nProtein 2,5 g\nGula 0 g',
    );
    expect(result.servingText, 'Takaran saji 30 g');
    expect(result.nutrients['Energi'], 120);
    expect(result.nutrients['Protein'], 2.5);
    expect(result.nutrients['Gula'], 0);
    expect(result.nutrients['Natrium'], isNull);
  });
  test('rejects ambiguous columns, repeated nutrients and wrong units', () {
    final result = extractLabel(
      'Protein 2 g 4 g\nGula 3 g\nGula 6 g\nNatrium 2 g',
    );
    expect(result.nutrients['Protein'], isNull);
    expect(result.nutrients['Gula'], isNull);
    expect(result.nutrients['Natrium'], isNull);
  });
  test('reads split lines without treating ingredient text as nutrients', () {
    final result = extractLabel(
      'Protein\n5 g\nKomposisi: gula, garam\nSodium 90 mg 4%',
    );
    expect(result.nutrients['Protein'], 5);
    expect(result.nutrients['Gula'], isNull);
    expect(result.nutrients['Natrium'], 90);
  });
}
