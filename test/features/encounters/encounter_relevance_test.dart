import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/encounter_relevance.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  final me = const UserProfile(
    id: 'a',
    displayName: 'A',
    interests: ['Music', ' art '],
    languages: ['English'],
    connectionGoal: ConnectionGoal.social,
  );
  UserProfile other({
    List<String> interests = const [],
    List<String> languages = const [],
    ConnectionGoal? goal,
  }) => UserProfile(
    id: 'b',
    displayName: 'B',
    interests: interests,
    languages: languages,
    connectionGoal: goal,
  );
  Encounter encounter(Duration duration, {String id = 'e'}) => Encounter(
    id: id,
    currentUserId: 'a',
    otherUserId: 'b',
    eventId: 'event',
    overlapStart: DateTime.utc(2026, 1, 1),
    overlapEnd: DateTime.utc(2026, 1, 1).add(duration),
  );

  test('ranks eligible encounters deterministically and bounds score', () {
    final result = const EncounterRankingService().rank(
      eligibleEncounters: [
        encounter(const Duration(minutes: 5)),
        encounter(const Duration(minutes: 40), id: 'z'),
      ],
      currentUser: me,
      profiles: {
        'b': other(
          interests: ['music', 'ART'],
          languages: ['english'],
          goal: ConnectionGoal.social,
        ),
      },
    );
    expect(result.first.encounter.id, 'z');
    expect(
      result.every((r) => r.relevance.score >= 0 && r.relevance.score <= 1),
      isTrue,
    );
  });

  test('profile signals contribute and overlap is capped', () {
    final service = const EncounterRankingService();
    final low = service
        .rank(
          eligibleEncounters: [encounter(const Duration(minutes: 5))],
          currentUser: me,
          profiles: {'b': other()},
        )
        .single
        .relevance
        .score;
    final high = service
        .rank(
          eligibleEncounters: [encounter(const Duration(minutes: 30))],
          currentUser: me,
          profiles: {
            'b': other(
              interests: ['music', 'art'],
              languages: ['English'],
              goal: ConnectionGoal.social,
            ),
          },
        )
        .single
        .relevance
        .score;
    final longer = service
        .rank(
          eligibleEncounters: [encounter(const Duration(hours: 8))],
          currentUser: me,
          profiles: {
            'b': other(
              interests: ['music', 'art'],
              languages: ['English'],
              goal: ConnectionGoal.social,
            ),
          },
        )
        .single
        .relevance
        .score;
    expect(high, greaterThan(low));
    expect(longer, high);
  });

  test('missing optional data is neutral and personality is not required', () {
    final result = const EncounterRankingService()
        .rank(
          eligibleEncounters: [encounter(const Duration(minutes: 5))],
          currentUser: me,
          profiles: {},
        )
        .single
        .relevance;
    expect(
      result.signals.where((s) => s.state == SignalState.unknown),
      isNotEmpty,
    );
    expect(result.score, greaterThan(0));
  });
}
