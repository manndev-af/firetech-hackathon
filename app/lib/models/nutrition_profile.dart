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

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'preference': preference,
    'priorities': priorities,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'eatingPattern': eatingPattern,
    'prefersHalal': prefersHalal,
    'allergyStatus': allergyStatus.name,
    'allergies': allergies,
    'otherAllergies': otherAllergies,
  };

  factory NutritionProfile.fromJson(Map<String, dynamic> json) =>
      NutritionProfile(
        name: json['name'] as String? ?? '',
        age: json['age'] as int?,
        preference: json['preference'] as String?,
        priorities: List<String>.from(json['priorities'] as List? ?? []),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        eatingPattern: json['eatingPattern'] as String?,
        prefersHalal: json['prefersHalal'] as bool? ?? false,
        allergyStatus: () {
          final raw = json['allergyStatus'] as String?;
          if (raw == null) return AllergyStatus.unknown;
          for (final status in AllergyStatus.values) {
            if (status.name == raw) return status;
          }
          if (raw == 'none') return AllergyStatus.noneKnown;
          return AllergyStatus.unknown;
        }(),
        allergies: List<String>.from(json['allergies'] as List? ?? []),
        otherAllergies: json['otherAllergies'] as String? ?? '',
      );

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

  NutritionProfile withOnboardingChoices(String focus, String? preference) {
    List<String> newPriorities;
    if (focus == 'Gula' && priorities.length > 1 && priorities.first == 'Gula') {
      newPriorities = priorities;
    } else {
      newPriorities = [focus];
    }
    return NutritionProfile(
      name: name,
      age: age,
      preference: preference,
      priorities: newPriorities,
      heightCm: heightCm,
      weightKg: weightKg,
      eatingPattern: eatingPattern,
      prefersHalal: prefersHalal,
      allergyStatus: allergyStatus,
      allergies: allergies,
      otherAllergies: otherAllergies,
    );
  }
}

enum AllergyStatus { unknown, noneKnown, listed }
