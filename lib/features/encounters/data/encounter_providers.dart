import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../events/data/event_providers.dart';
import '../../events/domain/event_check_in.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'local_encounter_repository.dart';

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
  return LocalEncounterRepository(
    currentUserPresence: local,
    otherUserPresence: demoPresence,
    referenceTime: ref.watch(utcNowProvider)().toUtc(),
  );
});
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((
  ref,
) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  return ref.watch(encounterRepositoryProvider).getEncountersForUser(user.id);
});
