import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../events/data/event_providers.dart';
import '../../events/data/mock_event_attendees.dart';
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
  return LocalEncounterRepository(
    currentUserPresence: local,
    otherUserPresence: mockEventAttendees,
  );
});
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((
  ref,
) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  return ref.watch(encounterRepositoryProvider).getEncountersForUser(user.id);
});
