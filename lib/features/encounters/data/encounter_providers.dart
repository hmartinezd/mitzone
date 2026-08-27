import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../../events/data/event_providers.dart';
import '../../events/data/mock_event_attendees.dart';
import '../../events/domain/event_check_in.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'local_encounter_repository.dart';

final encounterRepositoryProvider = Provider((ref) {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  final checkIns = ref.watch(eventCheckInsProvider);
  final local = checkIns.hasValue ? checkIns.value : const <EventCheckIn>[];
  return LocalEncounterRepository(
    currentUserPresence: local,
    otherUserPresence: mockEventAttendees,
  );
});
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((ref) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  return ref.watch(encounterRepositoryProvider).getEncountersForUser(user.id);
});
