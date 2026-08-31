import 'personality_profile.dart';
import 'personality_question.dart';

class PersonalityScoringService {
  const PersonalityScoringService();
  PersonalityProfile? score({
    required String userId,
    required Map<String, int> answers,
    DateTime? completedAt,
  }) {
    if (answers.length < personalityQuestions.length) return null;
    final values = <PersonalityTrait, double>{};
    for (final trait in PersonalityTrait.values) {
      final items = personalityQuestions.where((q) => q.trait == trait);
      if (items.any((q) => !answers.containsKey(q.id))) return null;
      values[trait] =
          items
              .map((q) {
                final raw = (answers[q.id] ?? 1).clamp(1, 4);
                return (q.reverse ? 5 - raw : raw) / 4;
              })
              .reduce((a, b) => a + b) /
          items.length;
    }
    return PersonalityProfile(
      userId: userId,
      traits: values,
      version: 1,
      completedAt: completedAt ?? DateTime.now().toUtc(),
    );
  }
}
