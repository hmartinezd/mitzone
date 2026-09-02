import '../domain/foreground_presence_controller.dart';
import '../domain/location_observation.dart';
import 'foreground_location_sources.dart';

abstract interface class ForegroundPresenceGateway {
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude});
  Future<void> stopForegroundPresence();
}

class DemoForegroundPresenceGateway implements ForegroundPresenceGateway {
  const DemoForegroundPresenceGateway();
  @override
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude}) async => DateTime.now().toUtc().add(const Duration(minutes: 30));
  @override
  Future<void> stopForegroundPresence() async {}
}

/// Coordinates one explicit foreground observation with the existing backend pipeline.
class ForegroundPresenceService {
  const ForegroundPresenceService({required this.location, required this.presence});
  final LocationObservationSource location;
  final ForegroundPresenceGateway presence;
  DateTime? expiresAt;
  ForegroundLocationFailure? lastLocationFailure;

  Future<ForegroundPresenceStatus> record({required bool consent}) async {
    if (!consent) return ForegroundPresenceStatus.denied;
    try {
      final observation = await location.observeForeground();
      expiresAt = await presence.recordForegroundPresence(
        latitude: observation.latitude,
        longitude: observation.longitude,
      );
      return ForegroundPresenceStatus.recorded;
    } on ForegroundLocationException catch (error) {
      lastLocationFailure = error.failure;
      return ForegroundPresenceStatus.unavailable;
    } catch (_) {
      return ForegroundPresenceStatus.unavailable;
    }
  }
}
