import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../../events/data/event_providers.dart';
import '../../events/data/mock_event_attendees.dart';
import '../../events/domain/event.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/encounter.dart';
import 'local_encounter_repository.dart';

final encounterRepositoryProvider = Provider((ref) {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  final local = ref.watch(eventCheckInsProvider).valueOrNull ?? const [];
  return LocalEncounterRepository(
    currentUserPresence: local,
    otherUserPresence: mockEventAttendees,
  );
});
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((ref) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  return ref.watch(encounterRepositoryProvider).getEncountersForUser(user.id);
});

final encounterProfileProvider = Provider.family<UserProfile, String>(
  (ref, id) => ref.watch(mockIdentityRepositoryProvider).users.firstWhere((u) => u.id == id),
);
final encounterEventProvider = Provider.family<Event?, String>(
  (ref, id) => ref.watch(eventCatalogProvider).getById(id),
);
