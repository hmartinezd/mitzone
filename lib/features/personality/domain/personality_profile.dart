enum PersonalityTrait {
  openness,
  conscientiousness,
  extraversion,
  agreeableness,
  emotionalStability,
}

class PersonalityProfile {
  const PersonalityProfile({
    required this.userId,
    required this.traits,
    required this.version,
    required this.completedAt,
    this.visibility = 'private',
  });
  final String userId;
  final Map<PersonalityTrait, double> traits;
  final int version;
  final DateTime completedAt;
  final String visibility;

  double value(PersonalityTrait trait) => traits[trait] ?? 0.5;
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'traits': {
      for (final e in traits.entries) e.key.name: e.value.clamp(0.0, 1.0),
    },
    'version': version,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'visibility': visibility,
  };
  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['traits'] is Map
        ? (json['traits'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final traits = <PersonalityTrait, double>{};
    for (final trait in PersonalityTrait.values) {
      final value = raw[trait.name];
      if (value is num) traits[trait] = value.toDouble().clamp(0.0, 1.0);
    }
    return PersonalityProfile(
      userId: json['userId'] as String,
      traits: traits,
      version: (json['version'] as num?)?.toInt() ?? 1,
      completedAt: DateTime.parse(json['completedAt'] as String),
      visibility: json['visibility'] as String? ?? 'private',
    );
  }
}
