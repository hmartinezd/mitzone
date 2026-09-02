import '../../../core/errors/domain_error.dart';

/// Ephemeral device observation. It must never be persisted or placed in an encounter.
class LocationObservation {
  LocationObservation({required this.latitude, required this.longitude, required this.observedAt}) {
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 || !observedAt.isUtc) {
      throw const DomainError(DomainErrorCode.validation, 'Invalid location observation');
    }
  }
  final double latitude;
  final double longitude;
  final DateTime observedAt;
}

abstract interface class LocationObservationSource {
  Future<LocationObservation> observeForeground();
}
