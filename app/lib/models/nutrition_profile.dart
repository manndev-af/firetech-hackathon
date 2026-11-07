class NutritionProfile {
  NutritionProfile({
    this.name = '',
    this.age,
    this.preference,
    this.heightCm,
    this.weightKg,
    this.eatingPattern,
    this.prefersHalal = false,
    this.allergyStatus = AllergyStatus.unknown,
    this.otherAllergies = '',
    Iterable<String> allergies = const [],
    Iterable<String> priorities = const [],
  }) : priorities = List.unmodifiable(priorities),
       allergies = List.unmodifiable(allergies);

  static const priorityOptions = [
    'Gula',
    'Natrium',
    'Protein',
    'Kalori',
    'Keseimbangan',
  ];

  final String name;
  final int? age;
  final String? preference;
  final List<String> priorities;
  final double? heightCm;
  final double? weightKg;
  final String? eatingPattern;
  final bool prefersHalal;
  final AllergyStatus allergyStatus;
  final List<String> allergies;
  final String otherAllergies;

  static const eatingPatterns = [
    'Fleksibel',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
  ];
  static const allergyOptions = [
    'Susu',
    'Telur',
    'Kacang tanah',
    'Kacang pohon',
    'Kedelai',
    'Gandum',
    'Ikan',
    'Kerang / udang',
  ];

  NutritionProfile withOnboardingChoices(String focus, String? preference) =>
      NutritionProfile(
        name: name,
        age: age,
        preference: preference,
        priorities: [focus],
        heightCm: heightCm,
        weightKg: weightKg,
        eatingPattern: eatingPattern,
        prefersHalal: prefersHalal,
        allergyStatus: allergyStatus,
        allergies: allergies,
        otherAllergies: otherAllergies,
      );
}

enum AllergyStatus { unknown, noneKnown, listed }
