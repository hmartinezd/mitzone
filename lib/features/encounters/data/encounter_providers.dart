import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../events/data/event_providers.dart';
import '../../events/domain/event_check_in.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'local_encounter_repository.dart';
import '../../blocking/data/block_providers.dart';

/// Local-demo encounters are observed after deterministic simulated elapsed
/// time so a fresh check-in immediately demonstrates meaningful overlap.
final demoEncounterObservationOffsetProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 45),
);

final encounterRepositoryProvider = Provider((ref) {
  final checkIns = ref.watch(eventCheckInsProvider);
  final local = checkIns.when(
    data: (value) => value,
    loading: () => const <EventCheckIn>[],
    error: (_, _) => const <EventCheckIn>[],
  );
  final demoPresence = <EventCheckIn>[
    for (final checkIn in local)
      ...ref.watch(
        mockEventAttendeesProvider((
          eventId: checkIn.eventId,
          referenceTime: checkIn.checkedInAt,
        )),
      ),
  ];
  final latestCheckIn = local.fold<DateTime?>(
    null,
    (latest, checkIn) => latest == null || checkIn.checkedInAt.isAfter(latest)
        ? checkIn.checkedInAt
        : latest,
  );
  final observationTime = latestCheckIn == null
      ? ref.watch(utcNowProvider)().toUtc()
      : latestCheckIn.add(ref.watch(demoEncounterObservationOffsetProvider));
  return LocalEncounterRepository(
    currentUserPresence: local,
    otherUserPresence: demoPresence,
    referenceTime: observationTime,
  );
});
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((
  ref,
) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  final encounters = await ref
      .watch(encounterRepositoryProvider)
      .getEncountersForUser(user.id);
  final result = <Encounter>[];
  for (final encounter in encounters) {
    if (!await ref
        .read(blockRepositoryProvider)
        .isPairBlocked(user.id, encounter.otherUserId))
      result.add(encounter);
  }
  return result;
});
