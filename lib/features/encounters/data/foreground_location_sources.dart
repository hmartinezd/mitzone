import 'package:geolocator/geolocator.dart';
import '../domain/location_observation.dart';

/// Production foreground-only location adapter. No stream or background API is used.
class PlatformForegroundLocationSource implements LocationObservationSource {
  const PlatformForegroundLocationSource();

  @override
  Future<LocationObservation> observeForeground() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location service is unavailable');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Foreground location permission denied');
    }
    if (permission != LocationPermission.whileInUse) {
      throw StateError('Foreground location permission required');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.balanced),
    );
    return LocationObservation(
      latitude: position.latitude,
      longitude: position.longitude,
      observedAt: position.timestamp?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}

class DemoForegroundLocationSource implements LocationObservationSource {
  const DemoForegroundLocationSource({this.latitude = 40.7128, this.longitude = -74.006});
  final double latitude;
  final double longitude;
  @override
  Future<LocationObservation> observeForeground() async => LocationObservation(
    latitude: latitude, longitude: longitude, observedAt: DateTime.now().toUtc(),
  );
}
