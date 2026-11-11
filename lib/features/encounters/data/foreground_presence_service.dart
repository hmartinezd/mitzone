import 'dart:async';

import '../domain/foreground_presence_controller.dart';
import '../domain/location_observation.dart';
import 'foreground_location_sources.dart';

abstract interface class ForegroundPresenceGateway {
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  });
  Future<void> stopForegroundPresence();
}

/// A refresh must update an existing server lease, never create a new one.
abstract interface class ForegroundPresenceRefreshGateway {
  Future<DateTime> refreshForegroundPresence({
    required double latitude,
    required double longitude,
  });
}

class DemoForegroundPresenceGateway implements ForegroundPresenceGateway {
  const DemoForegroundPresenceGateway();
  @override
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  }) async => DateTime.now().toUtc().add(const Duration(minutes: 30));
  @override
  Future<void> stopForegroundPresence() async {}
}

/// Coordinates one explicit foreground observation with the existing backend pipeline.
class ForegroundPresenceService {
  ForegroundPresenceService({
    required this.location,
    required this.presence,
    DateTime Function()? now,
  }) : now = now ?? (() => DateTime.now().toUtc());
  final LocationObservationSource location;
  final ForegroundPresenceGateway presence;
  final DateTime Function() now;
  DateTime? expiresAt;
  ForegroundLocationFailure? lastLocationFailure;
  bool _recording = false;
  int _generation = 0;
  Future<DateTime>? _recordRequest;

  Future<ForegroundPresenceStatus> record({
    required bool consent,
    void Function()? onLocationResolved,
    bool Function()? isStillAuthorized,
  }) => _submit(
    consent: consent,
    onLocationResolved: onLocationResolved,
    isStillAuthorized: isStillAuthorized,
    refresh: false,
  );

  Future<ForegroundPresenceStatus> refresh({
    required bool consent,
    bool Function()? isStillAuthorized,
  }) => _submit(
    consent: consent,
    isStillAuthorized: isStillAuthorized,
    refresh: true,
  );

  Future<ForegroundPresenceStatus> _submit({
    required bool consent,
    required bool refresh,
    void Function()? onLocationResolved,
    bool Function()? isStillAuthorized,
  }) async {
    if (!consent) return ForegroundPresenceStatus.denied;
    if (refresh && presence is! ForegroundPresenceRefreshGateway) {
      return ForegroundPresenceStatus.unavailable;
    }
    if (refresh && (expiresAt == null || !now().isBefore(expiresAt!))) {
      return ForegroundPresenceStatus.unavailable;
    }
    if (_recording) return ForegroundPresenceStatus.unavailable;
    _recording = true;
    final generation = _generation;
    lastLocationFailure = null;
    try {
      final observation = await location.observeForeground().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const ForegroundLocationException(
          ForegroundLocationFailure.temporarilyUnavailable,
        ),
      );
      final observationAge = now().toUtc().difference(observation.observedAt);
      if (!observation.observedAt.isUtc ||
          observationAge > const Duration(seconds: 30) ||
          observationAge < const Duration(seconds: -5)) {
        throw const ForegroundLocationException(
          ForegroundLocationFailure.temporarilyUnavailable,
        );
      }
      // Auth/account may change while the platform observation is pending.
      // Never apply consent from the previous account to the next one.
      if (generation != _generation ||
          (isStillAuthorized != null && !isStillAuthorized())) {
        return ForegroundPresenceStatus.denied;
      }
      onLocationResolved?.call();
      final request = refresh
          ? (presence as ForegroundPresenceRefreshGateway)
                .refreshForegroundPresence(
                  latitude: observation.latitude,
                  longitude: observation.longitude,
                )
          : presence.recordForegroundPresence(
              latitude: observation.latitude,
              longitude: observation.longitude,
            );
      _recordRequest = request;
      final returnedExpiry = await request;
      if (!refresh ||
          expiresAt == null ||
          returnedExpiry.isBefore(expiresAt!)) {
        expiresAt = returnedExpiry;
      }
      return ForegroundPresenceStatus.recorded;
    } on ForegroundLocationException catch (error) {
      lastLocationFailure = error.failure;
      return ForegroundPresenceStatus.unavailable;
    } catch (_) {
      return ForegroundPresenceStatus.unavailable;
    } finally {
      _recording = false;
      _recordRequest = null;
    }
  }

  /// Clear local presentation state only after the server confirms Stop.
  Future<void> stop() async {
    cancelPendingObservation();
    // If a write already left the device, Stop must follow its completion.
    // Otherwise a late record response could recreate presence after Stop.
    final request = _recordRequest;
    if (request != null) {
      try {
        await request;
      } catch (_) {
        // Stop is still required after an uncertain/failed record response.
      }
    }
    await presence.stopForegroundPresence();
    expiresAt = null;
  }

  /// Cancels permission to submit an observation, without claiming server Stop.
  void cancelPendingObservation() => _generation++;
}
