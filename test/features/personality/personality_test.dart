import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/personality/domain/personality_compatibility.dart';
import 'package:mitzone/features/personality/domain/personality_profile.dart';
import 'package:mitzone/features/personality/domain/personality_question.dart';
import 'package:mitzone/features/personality/domain/personality_scoring.dart';

void main() {
  test('scoring is deterministic, bounded, and reverse keyed', () {
    final answers = {for (final q in personalityQuestions) q.id: 1};
    final profile = const PersonalityScoringService().score(
      userId: 'u',
      answers: answers,
      completedAt: DateTime.utc(2026),
    )!;
    expect(profile.value(PersonalityTrait.openness), .5);
    for (final value in profile.traits.values) {
      expect(value, inInclusiveRange(0, 1));
    }
    expect(
      const PersonalityScoringService()
          .score(
            userId: 'u',
            answers: answers,
            completedAt: DateTime.utc(2026),
          )!
          .toJson(),
      profile.toJson(),
    );
  });

  test('reverse-keyed items invert their contribution to the trait average', () {
    const service = PersonalityScoringService();
    final baseline = {for (final q in personalityQuestions) q.id: 1};
    final original = service.score(
      userId: 'u',
      answers: baseline,
      completedAt: DateTime.utc(2026),
    )!;
    final reverseItems = personalityQuestions.where((q) => q.reverse).toList();
    expect(reverseItems, isNotEmpty);
    for (final question in reverseItems) {
      final changed = service.score(
        userId: 'u',
        answers: {...baseline, question.id: 4},
        completedAt: DateTime.utc(2026),
      )!;
      // A reverse response 1 contributes 4/4; response 4 contributes 1/4.
      // Each trait averages three items, so changing this item lowers it by .25.
      expect(
        changed.value(question.trait),
        original.value(question.trait) - .25,
      );
      for (final trait in PersonalityTrait.values.where(
        (t) => t != question.trait,
      )) {
        expect(changed.value(trait), original.value(trait));
      }
    }
  });

  test('incomplete answers are safe', () {
    expect(
      const PersonalityScoringService().score(userId: 'u', answers: {}),
      isNull,
    );
  });

  test('compatibility is optional, symmetric, and bounded', () {
    final traits = {for (final trait in PersonalityTrait.values) trait: .5};
    final a = PersonalityProfile(
      userId: 'a',
      traits: traits,
      version: 1,
      completedAt: DateTime.utc(2026),
    );
    final b = PersonalityProfile(
      userId: 'b',
      traits: traits,
      version: 1,
      completedAt: DateTime.utc(2026),
    );
    final service = const PersonalityCompatibilityService();
    expect(service.compare(a, null), isNull);
    expect(service.compare(a, b)!.value, inInclusiveRange(0, 1));
    expect(service.compare(a, b)!.value, service.compare(b, a)!.value);
  });
}
