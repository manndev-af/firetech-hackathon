class ScanDraft {
  const ScanDraft({
    required this.id,
    required this.photoPath,
    required this.label,
    required this.createdAt,
    required this.priorities,
    this.rawOcrText,
  });
  final String id;
  final String photoPath;
  final bool label;
  final DateTime createdAt;
  final List<String> priorities;
  final String? rawOcrText;
  Map<String, dynamic> toJson() => {
    'id': id,
    'photoPath': photoPath,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'priorities': priorities,
    'rawOcrText': rawOcrText,
  };
  factory ScanDraft.fromJson(Map<String, dynamic> json) => ScanDraft(
    id: json['id'] as String,
    photoPath: json['photoPath'] as String,
    label: json['label'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    priorities: List<String>.from(json['priorities'] as List),
    rawOcrText: json['rawOcrText'] as String?,
  );
}
