import '../../profile/domain/user_profile.dart';
import 'encounter.dart';
import 'profile_affinity.dart';

enum RelevanceSignal { sharedContext, overlap, interests, languages, goals, profileCompleteness, personalityCompatibility }

enum SignalState { positive, neutral, incompatible, unknown }

class RelevanceSignalResult {
  const RelevanceSignalResult(this.signal, this.state, this.value);
  final RelevanceSignal signal;
  final SignalState state;
  final double value;
}

class EncounterRelevance {
  const EncounterRelevance({required this.encounterId, required this.score, required this.signals});
  final String encounterId;
  final double score;
  final List<RelevanceSignalResult> signals;
}

class RankedEncounter {
  const RankedEncounter(this.encounter, this.relevance);
  final Encounter encounter;
  final EncounterRelevance relevance;
}

class EncounterRankingWeights {
  const EncounterRankingWeights({
    this.sharedContext = .135, this.overlap = .18, this.interests = .225,
    this.languages = .135, this.goals = .135, this.profileCompleteness = .09,
    this.personalityCompatibility = .10,
  });
  final double sharedContext, overlap, interests, languages, goals, profileCompleteness, personalityCompatibility;
}

class EncounterRankingService {
  const EncounterRankingService({this.weights = const EncounterRankingWeights()});
  final EncounterRankingWeights weights;

  List<RankedEncounter> rank({required List<Encounter> eligibleEncounters, required UserProfile? currentUser, required Map<String, UserProfile> profiles, Map<String, double> personalityCompatibility = const {}}) {
    final ranked = [
      for (final encounter in eligibleEncounters)
        _rankOne(encounter, currentUser, profiles[encounter.otherUserId], personalityCompatibility[encounter.otherUserId]),
    ];
    ranked.sort((a, b) {
      final score = b.relevance.score.compareTo(a.relevance.score);
      return score == 0 ? a.encounter.id.compareTo(b.encounter.id) : score;
    });
    return ranked;
  }

  RankedEncounter _rankOne(Encounter encounter, UserProfile? current, UserProfile? other, double? compatibility) {
    final signals = <RelevanceSignalResult>[];
    void add(RelevanceSignal signal, SignalState state, double value) => signals.add(RelevanceSignalResult(signal, state, value));
    add(RelevanceSignal.sharedContext, SignalState.positive, 1);
    final overlap = (encounter.overlapDuration.inMinutes / 30).clamp(0.0, 1.0).toDouble();
    add(RelevanceSignal.overlap, overlap == 0 ? SignalState.neutral : SignalState.positive, overlap);
    if (other == null || current == null) {
      add(RelevanceSignal.interests, SignalState.unknown, 0);
      add(RelevanceSignal.languages, SignalState.unknown, 0);
      add(RelevanceSignal.goals, SignalState.unknown, 0);
      add(RelevanceSignal.profileCompleteness, SignalState.unknown, 0);
    } else {
      final interests = ProfileAffinity.sharedInterests(current, other).length;
      add(RelevanceSignal.interests, interests == 0 ? SignalState.neutral : SignalState.positive, (interests / 5).clamp(0.0, 1.0).toDouble());
      final languages = ProfileAffinity.sharedLanguages(current, other).length;
      add(RelevanceSignal.languages, languages == 0 ? SignalState.neutral : SignalState.positive, languages > 0 ? 1 : 0);
      final goals = current.connectionGoal == null || other.connectionGoal == null ? SignalState.unknown : (current.connectionGoal == other.connectionGoal ? SignalState.positive : SignalState.neutral);
      add(RelevanceSignal.goals, goals, goals == SignalState.positive ? 1 : 0);
      add(RelevanceSignal.profileCompleteness, SignalState.positive, ((current.completionPercentage + other.completionPercentage) / 200).clamp(0.0, 1.0).toDouble());
    }
    add(RelevanceSignal.personalityCompatibility, compatibility == null ? SignalState.unknown : SignalState.positive, compatibility ?? 0);
    final score = (weights.sharedContext * signals[0].value + weights.overlap * signals[1].value + weights.interests * signals[2].value + weights.languages * signals[3].value + weights.goals * signals[4].value + weights.profileCompleteness * signals[5].value + weights.personalityCompatibility * signals[6].value).clamp(0.0, 1.0).toDouble();
    return RankedEncounter(encounter, EncounterRelevance(encounterId: encounter.id, score: score, signals: List.unmodifiable(signals)));
  }
}
