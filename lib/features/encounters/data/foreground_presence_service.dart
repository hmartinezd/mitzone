import '../domain/foreground_presence_controller.dart';
import '../domain/location_observation.dart';
import '../domain/presence_consent.dart';
import 'supabase_presence_repository.dart';

abstract interface class ForegroundPresenceGateway {
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude});
  Future<void> stopForegroundPresence();
}

/// Coordinates one explicit foreground observation with the existing backend pipeline.
class ForegroundPresenceService {
  const ForegroundPresenceService({required this.location, required this.presence});
  final LocationObservationSource location;
  final ForegroundPresenceGateway presence;

  Future<ForegroundPresenceStatus> record({required bool consent, required LocationPermissionState permission}) async {
    if (!consent) return ForegroundPresenceStatus.denied;
    if (permission == LocationPermissionState.deniedForever) return ForegroundPresenceStatus.denied;
    try {
      final observation = await location.observeForeground();
      await presence.recordForegroundPresence(
        latitude: observation.latitude,
        longitude: observation.longitude,
      );
      return ForegroundPresenceStatus.recorded;
    } catch (_) {
      return ForegroundPresenceStatus.unavailable;
    }
  }
}
