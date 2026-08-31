import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/personality/domain/personality_compatibility.dart';
import 'package:mitzone/features/personality/domain/personality_profile.dart';
import 'package:mitzone/features/personality/domain/personality_question.dart';
import 'package:mitzone/features/personality/domain/personality_scoring.dart';

void main() {
  test('scoring is deterministic, bounded, and reverse keyed', () {
    final answers = {for (final q in personalityQuestions) q.id: 1};
    final profile = const PersonalityScoringService().score(userId: 'u', answers: answers)!;
    expect(profile.value(PersonalityTrait.openness), .25);
    for (final value in profile.traits.values) {
      expect(value, inInclusiveRange(0, 1));
    }
    expect(const PersonalityScoringService().score(userId: 'u', answers: answers)!.toJson(), profile.toJson());
  });

  test('incomplete answers are safe', () {
    expect(const PersonalityScoringService().score(userId: 'u', answers: {}), isNull);
  });

  test('compatibility is optional, symmetric, and bounded', () {
    final traits = {for (final trait in PersonalityTrait.values) trait: .5};
    final a = PersonalityProfile(userId: 'a', traits: traits, version: 1, completedAt: DateTime.utc(2026));
    final b = PersonalityProfile(userId: 'b', traits: traits, version: 1, completedAt: DateTime.utc(2026));
    final service = const PersonalityCompatibilityService();
    expect(service.compare(a, null), isNull);
    expect(service.compare(a, b)!.value, inInclusiveRange(0, 1));
    expect(service.compare(a, b)!.value, service.compare(b, a)!.value);
  });
}
