import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../domain/encounter.dart';
import 'local_encounter_repository.dart';

final encounterRepositoryProvider = Provider((ref) => const LocalEncounterRepository());
final encountersForCurrentUserProvider = FutureProvider<List<Encounter>>((ref) async {
  final user = ref.watch(mockIdentityRepositoryProvider).currentUser;
  return ref.watch(encounterRepositoryProvider).getEncountersForUser(user.id);
});
