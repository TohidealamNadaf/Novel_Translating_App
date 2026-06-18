import 'package:uuid/uuid.dart';

class GlossaryEntry {
  final String id;
  final String novelId;
  final String original;
  String translated;
  String? gender; // 'male', 'female', 'neutral', null
  String type; // 'character', 'place', 'term', 'title', 'technique', 'item'
  bool isActive;
  final DateTime createdAt;

  GlossaryEntry({
    String? id,
    required this.novelId,
    required this.original,
    required this.translated,
    this.gender,
    this.type = 'term',
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'novelId': novelId,
      'original': original,
      'translated': translated,
      'gender': gender,
      'type': type,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GlossaryEntry.fromMap(Map<String, dynamic> map) {
    return GlossaryEntry(
      id: map['id'] as String,
      novelId: map['novelId'] as String,
      original: map['original'] as String,
      translated: map['translated'] as String,
      gender: map['gender'] as String?,
      type: map['type'] as String? ?? 'term',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  GlossaryEntry copyWith({
    String? translated,
    String? gender,
    String? type,
    bool? isActive,
  }) {
    return GlossaryEntry(
      id: id,
      novelId: novelId,
      original: original,
      translated: translated ?? this.translated,
      gender: gender ?? this.gender,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  /// Format for prompt injection: "Original → Translation (Gender)"
  String toPromptLine() {
    final genderSuffix = gender != null ? ' ($gender)' : '';
    return '$original → $translated$genderSuffix';
  }
}
