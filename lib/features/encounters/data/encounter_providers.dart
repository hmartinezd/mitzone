import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../events/data/event_providers.dart';
import '../../events/domain/event_check_in.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'local_encounter_repository.dart';
import '../../blocking/data/block_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import 'supabase_encounter_repository.dart';
import '../domain/encounter_eligibility.dart';
import '../domain/encounter_relevance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/data/profile_providers.dart';
import '../../profile/domain/user_profile.dart';

/// Local-demo encounters are observed after deterministic simulated elapsed
/// time so a fresh check-in immediately demonstrates meaningful overlap.
final demoEncounterObservationOffsetProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 45),
);

final encounterRepositoryProvider = Provider((ref) {
  if (ref.watch(productionModeProvider)) {
    return SupabaseEncounterRepository(Supabase.instance.client);
  }
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
  final userId = ref.watch(productionModeProvider)
      ? await ref.watch(currentUserIdProvider.future)
      : ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  final encounters = await ref
      .watch(encounterRepositoryProvider)
      .getEncountersForUser(userId);
  final result = <Encounter>[];
  for (final encounter in encounters) {
    if (await EncounterEligibilityPolicy(ref.read(blockRepositoryProvider))
            .evaluate(encounter) !=
        EncounterEligibility.unavailable)
      result.add(encounter);
  }
  final production = ref.watch(productionModeProvider);
  final profileRepository = ref.read(profileRepositoryProvider);
  late final UserProfile? current;
  late final Map<String, UserProfile> profiles;
  if (production) {
    current = await profileRepository.getProfile(userId).catchError((_) => null);
    profiles = await profileRepository
        .getProfilesByIds(result.map((e) => e.otherUserId).toSet())
        .catchError((_) => <String, UserProfile>{});
  } else {
    final identity = ref.watch(mockIdentityRepositoryProvider);
    current = identity.currentUser;
    profiles = {for (final profile in identity.users) profile.id: profile};
  }
  return [
    for (final ranked in const EncounterRankingService().rank(
      eligibleEncounters: result,
      currentUser: current,
      profiles: profiles,
    )) ranked.encounter,
  ];
});
