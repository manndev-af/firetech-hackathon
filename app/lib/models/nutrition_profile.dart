class NutritionProfile {
  NutritionProfile({
    this.name = '',
    this.age,
    this.preference,
    Iterable<String> priorities = const [],
  }) : priorities = List.unmodifiable(priorities);

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
}
