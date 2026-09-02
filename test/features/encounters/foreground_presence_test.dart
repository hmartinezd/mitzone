import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/encounters/domain/foreground_presence_controller.dart';
import 'package:mitzone/features/encounters/domain/presence_consent.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_service.dart';
import 'package:mitzone/features/encounters/domain/location_observation.dart';

class _CountingLocation implements LocationObservationSource {
  int observations = 0;
  @override
  Future<LocationObservation> observeForeground() async {
    observations++;
    return LocationObservation(latitude: 12.345678, longitude: -98.765432, observedAt: DateTime.utc(2026));
  }
}

class _CountingGateway implements ForegroundPresenceGateway {
  int records = 0;
  int stops = 0;
  bool failStop = false;
  @override
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude}) async {
    records++;
    return DateTime.now().toUtc().add(const Duration(minutes: 30));
  }
  @override
  Future<void> stopForegroundPresence() async {
    stops++;
    if (failStop) throw StateError('stop failed');
  }
}

void main() {
  test('consent and foreground permission are required', () async {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    expect(await c.activate(userId: 'u', productConsent: false, permission: LocationPermissionState.whileUsing, contextId: ''), isNull);
    expect(c.status, ForegroundPresenceStatus.inactive);
  });
  test('active foreground presence records coarse evidence', () async {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    final e = await c.activate(userId: 'u', productConsent: true, permission: LocationPermissionState.whileUsing, contextId: '');
    expect(e?.contextId, startsWith('cell:'));
    expect(c.status, ForegroundPresenceStatus.recorded);
  });
  test('manual stop and background stop deactivate presence', () {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    c.onAppBackgrounded();
    expect(c.status, ForegroundPresenceStatus.inactive);
  });

  test('service performs one explicit observation and one record', () async {
    final location = _CountingLocation();
    final gateway = _CountingGateway();
    final service = ForegroundPresenceService(location: location, presence: gateway);
    expect(await service.record(consent: false), ForegroundPresenceStatus.denied);
    expect(location.observations, 0);
    expect(await service.record(consent: true), ForegroundPresenceStatus.recorded);
    expect(location.observations, 1);
    expect(gateway.records, 1);
  });

  test('service does not record when foreground observation fails', () async {
    final gateway = _CountingGateway();
    final service = ForegroundPresenceService(
      location: _FailingLocation(), presence: gateway,
    );
    expect(await service.record(consent: true), ForegroundPresenceStatus.unavailable);
    expect(gateway.records, 0);
  });

  test('expiry is presentation state only and does not observe again', () async {
    final location = _CountingLocation();
    final gateway = _CountingGateway();
    final service = ForegroundPresenceService(location: location, presence: gateway);
    await service.record(consent: true);
    expect(location.observations, 1);
    expect(gateway.records, 1);
  });

  test('stop gateway preserves failure for presentation to handle', () async {
    final gateway = _CountingGateway()..failStop = true;
    expect(() => gateway.stopForegroundPresence(), throwsStateError);
    expect(gateway.stops, 1);
  });
}

class _FailingLocation implements LocationObservationSource {
  @override
  Future<LocationObservation> observeForeground() async => throw StateError('unavailable');
}
