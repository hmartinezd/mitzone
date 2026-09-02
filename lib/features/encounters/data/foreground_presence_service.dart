import '../domain/foreground_presence_controller.dart';
import '../domain/location_observation.dart';
import '../domain/presence_consent.dart';
import 'supabase_presence_repository.dart';
import '../domain/encounter_repository.dart';

/// Coordinates one explicit foreground observation with the existing backend pipeline.
class ForegroundPresenceService {
  const ForegroundPresenceService({required this.location, required this.presence, required this.encounters});
  final LocationObservationSource location;
  final SupabasePresenceRepository presence;
  final EncounterRepository encounters;

  Future<ForegroundPresenceStatus> record({required String userId, required bool consent, required LocationPermissionState permission}) async {
    if (!consent || permission != LocationPermissionState.whileUsing) return ForegroundPresenceStatus.denied;
    final observation = await location.observeForeground();
    final evidence = await presence.recordForegroundPresence(latitude: observation.latitude, longitude: observation.longitude);
    await encounters.processEvidence(evidence, actorUserId: userId);
    return ForegroundPresenceStatus.recorded;
  }
}
