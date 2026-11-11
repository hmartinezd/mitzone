import '../encounters/domain/location_observation.dart';

/// Production seam for a future platform location implementation. It fails closed.
class PlatformForegroundLocationSource implements LocationObservationSource {
  const PlatformForegroundLocationSource();
  @override
  Future<LocationObservation> observeForeground() =>
      Future.error(StateError('Foreground location is unavailable'));
}

/// Deterministic adapter used only by local/demo environments and tests.
class DemoForegroundLocationSource implements LocationObservationSource {
  const DemoForegroundLocationSource({
    this.latitude = 40.7128,
    this.longitude = -74.0060,
  });
  final double latitude;
  final double longitude;
  @override
  Future<LocationObservation> observeForeground() async => LocationObservation(
    latitude: latitude,
    longitude: longitude,
    observedAt: DateTime.now().toUtc(),
  );
}
