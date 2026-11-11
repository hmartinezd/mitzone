import 'personality_profile.dart';

class PersonalityCompatibility {
  const PersonalityCompatibility(this.value, this.components);
  final double value;
  final Map<PersonalityTrait, double> components;
}

class PersonalityCompatibilityService {
  const PersonalityCompatibilityService();
  PersonalityCompatibility? compare(
    PersonalityProfile? a,
    PersonalityProfile? b,
  ) {
    if (a == null || b == null) return null;
    final components = <PersonalityTrait, double>{};
    for (final trait in PersonalityTrait.values) {
      final difference = (a.value(trait) - b.value(trait)).abs();
      components[trait] = 1 - difference;
    }
    // Extraversion differences are neutral: different social styles can complement one another.
    components[PersonalityTrait.extraversion] = 0.5;
    final value =
        (components[PersonalityTrait.openness]! * .25 +
                components[PersonalityTrait.conscientiousness]! * .2 +
                components[PersonalityTrait.agreeableness]! * .25 +
                components[PersonalityTrait.emotionalStability]! * .2 +
                components[PersonalityTrait.extraversion]! * .1)
            .clamp(0.0, 1.0)
            .toDouble();
    return PersonalityCompatibility(value, Map.unmodifiable(components));
  }
}
