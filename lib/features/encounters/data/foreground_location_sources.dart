import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/location_observation.dart';

enum ForegroundLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  temporarilyUnavailable,
}

class ForegroundLocationException implements Exception {
  const ForegroundLocationException(this.failure);
  final ForegroundLocationFailure failure;
}

/// Production foreground-only location adapter. No stream or background API is used.
class PlatformForegroundLocationSource implements LocationObservationSource {
  const PlatformForegroundLocationSource();

  @override
  Future<LocationObservation> observeForeground() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ForegroundLocationException(
        ForegroundLocationFailure.servicesDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ForegroundLocationException(
        ForegroundLocationFailure.permissionPermanentlyDenied,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const ForegroundLocationException(
        ForegroundLocationFailure.permissionDenied,
      );
    }
    if (permission != LocationPermission.whileInUse) {
      throw const ForegroundLocationException(
        ForegroundLocationFailure.permissionDenied,
      );
    }
    late final Position position;
    final stopwatch = Stopwatch()..start();
    _logLocationDiagnostic('Current-position request started');
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      _logLocationDiagnostic(
        'Current-position request timed out '
        'after ${stopwatch.elapsedMilliseconds} ms',
      );
      throw const ForegroundLocationException(
        ForegroundLocationFailure.temporarilyUnavailable,
      );
    } catch (error) {
      final errorType = error is PlatformException
          ? '${error.runtimeType} code=${error.code}'
          : error.runtimeType.toString();
      _logLocationDiagnostic(
        'Current-position request failed '
        'after ${stopwatch.elapsedMilliseconds} ms '
        '(exception=$errorType)',
      );
      throw const ForegroundLocationException(
        ForegroundLocationFailure.temporarilyUnavailable,
      );
    }
    _logLocationDiagnostic(
      'Current-position request succeeded '
      'after ${stopwatch.elapsedMilliseconds} ms',
    );
    return LocationObservation(
      latitude: position.latitude,
      longitude: position.longitude,
      observedAt: position.timestamp.toUtc(),
    );
  }

  void _logLocationDiagnostic(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'mitzone.location');
  }
}

class DemoForegroundLocationSource implements LocationObservationSource {
  const DemoForegroundLocationSource({
    this.latitude = 40.7128,
    this.longitude = -74.006,
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
