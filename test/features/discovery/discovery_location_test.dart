import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/features/discovery/data/discovery_location_provider.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/features/discovery/domain/discovery_item.dart';
import 'package:mitzone/features/discovery/domain/discovery_repository.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_service.dart';
import 'package:mitzone/features/encounters/data/presence_providers.dart';
import 'package:mitzone/features/encounters/domain/foreground_presence_controller.dart';
import 'package:mitzone/features/encounters/domain/location_observation.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/data/event_repository.dart';
import 'package:mitzone/features/events/domain/event.dart';

void main() {
  late _Location location;
  late _Places places;
  late _Events events;
  late _Presence presence;
  late ProviderContainer container;
  const interests = <String>{};

  void setup({
    ForegroundLocationFailure? failure,
    bool stalledLocation = false,
    bool stalledPlaces = false,
  }) {
    location = _Location()..failure = failure;
    if (stalledLocation) location.pending = Completer<LocationObservation>();
    places = _Places();
    if (stalledPlaces) places.pending = Completer<List<DiscoveryItem>>();
    events = _Events();
    presence = _Presence();
    container = ProviderContainer(
      overrides: [
        productionModeProvider.overrideWithValue(true),
        authSessionProvider.overrideWithValue(
          const AsyncData(AuthSession(user: AuthUser(id: 'test-user'))),
        ),
        locationObservationSourceProvider.overrideWithValue(location),
        discoveryRepositoryProvider.overrideWithValue(places),
        eventRepositoryProvider.overrideWithValue(events),
        foregroundPresenceGatewayProvider.overrideWithValue(presence),
      ],
    );
    container.listen(nearbyDiscoveryProvider(interests), (_, _) {});
    container.listen(nearbyEventsProvider, (_, _) {});
  }

  test(
    'places and events share one observation without recording presence or joining',
    () async {
      setup();
      addTearDown(container.dispose);
      await Future.wait([
        container.read(nearbyDiscoveryProvider(interests).future),
        container.read(nearbyEventsProvider.future),
      ]);
      expect(location.calls, 1);
      expect(places.calls, 1);
      expect(events.calls, 1);
      expect(places.coordinates, (40.7, -74.0));
      expect(events.coordinates, places.coordinates);
      expect(presence.records, 0);
    },
  );

  for (final failure in ForegroundLocationFailure.values) {
    testWidgets(
      '$failure fails closed without automatic retries and supports explicit retry',
      (tester) async {
        setup(failure: failure);
        addTearDown(container.dispose);
        await tester.pump(Duration.zero);
        expect(
          container.read(nearbyDiscoveryProvider(interests)).error,
          isA<ForegroundLocationException>(),
        );
        expect(
          container.read(nearbyEventsProvider).error,
          isA<ForegroundLocationException>(),
        );
        await tester.pump(const Duration(minutes: 1));
        expect(location.calls, 1);
        expect(places.calls, 0);
        expect(events.calls, 0);
        expect(presence.records, 0);
        location.failure = null;
        container.invalidate(discoveryLocationProvider);
        container.invalidate(nearbyDiscoveryProvider(interests));
        container.invalidate(nearbyEventsProvider);
        final retried = Future.wait([
          container.read(nearbyDiscoveryProvider(interests).future),
          container.read(nearbyEventsProvider.future),
        ]);
        await tester.pump(Duration.zero);
        await retried;
        await tester.pump(Duration.zero);
        expect(location.calls, 2, reason: 'Location retry must execute');
        expect(
          container.read(nearbyDiscoveryProvider(interests)).hasValue,
          isTrue,
          reason:
              '${container.read(nearbyDiscoveryProvider(interests))}; places=${places.calls}; events=${events.calls}',
        );
        expect(container.read(nearbyEventsProvider).hasValue, isTrue);
        expect(location.calls, 2);
        expect(places.calls, 1);
        expect(events.calls, 1);
      },
    );
  }

  testWidgets(
    'a stalled fix times out and its late result never starts discovery or records presence',
    (tester) async {
      setup(stalledLocation: true);
      addTearDown(container.dispose);
      await tester.pump(Duration.zero);
      expect(
        container.read(nearbyDiscoveryProvider(interests)).isLoading,
        isTrue,
      );
      await tester.pump(discoveryRequestTimeout);
      final error = container.read(discoveryLocationProvider).error;
      expect(
        error,
        isA<ForegroundLocationException>().having(
          (e) => e.failure,
          'failure',
          ForegroundLocationFailure.temporarilyUnavailable,
        ),
      );
      location.pending!.complete(_observation());
      await tester.pump(Duration.zero);
      expect(places.calls, 0);
      expect(events.calls, 0);
      expect(presence.records, 0);
    },
  );

  testWidgets(
    'stalled discovery request times out without hiding successful event data',
    (tester) async {
      setup(stalledPlaces: true);
      addTearDown(container.dispose);
      await tester.pump(Duration.zero);
      await tester.pump(discoveryRequestTimeout);
      expect(
        container.read(nearbyDiscoveryProvider(interests)).error,
        isA<TimeoutException>(),
      );
      expect(container.read(nearbyEventsProvider).hasValue, isTrue);
      expect(location.calls, 1);
      expect(presence.records, 0);
    },
  );

  testWidgets(
    'explicit presence uses a fresh observation and a late timed-out fix never writes evidence',
    (tester) async {
      final source = _Location()..pending = Completer<LocationObservation>();
      final gateway = _Presence();
      final service = ForegroundPresenceService(
        location: source,
        presence: gateway,
      );
      final result = service.record(consent: true);
      await tester.pump(const Duration(seconds: 20));
      expect(await result, ForegroundPresenceStatus.unavailable);
      source.pending!.complete(_observation());
      await tester.pump(Duration.zero);
      expect(gateway.records, 0);
      expect(
        service.lastLocationFailure,
        ForegroundLocationFailure.temporarilyUnavailable,
      );
      source.pending = null;
      var resolved = false;
      expect(
        await service.record(
          consent: true,
          onLocationResolved: () => resolved = true,
        ),
        ForegroundPresenceStatus.recorded,
      );
      expect(resolved, isTrue);
      expect(service.lastLocationFailure, isNull);
      expect(source.calls, 2);
      expect(gateway.records, 1);
    },
  );
}

LocationObservation _observation() => LocationObservation(
  latitude: 40.7,
  longitude: -74,
  observedAt: DateTime.now().toUtc(),
);

class _Location implements LocationObservationSource {
  int calls = 0;
  ForegroundLocationFailure? failure;
  Completer<LocationObservation>? pending;
  @override
  Future<LocationObservation> observeForeground() async {
    calls++;
    if (failure != null) throw ForegroundLocationException(failure!);
    return pending?.future ?? Future.value(_observation());
  }
}

class _Places implements DiscoveryRepository {
  int calls = 0;
  (double?, double?)? coordinates;
  Completer<List<DiscoveryItem>>? pending;
  @override
  Future<List<DiscoveryItem>> getNearby({
    Set<String> interests = const {},
    double? latitude,
    double? longitude,
    DateTime? now,
  }) async {
    calls++;
    coordinates = (latitude, longitude);
    return pending?.future ?? Future.value([]);
  }
}

class _Events implements EventRepository {
  int calls = 0;
  (double?, double?)? coordinates;
  @override
  Future<List<Event>> getNearby({
    required double latitude,
    required double longitude,
  }) async {
    calls++;
    coordinates = (latitude, longitude);
    return [];
  }
}

class _Presence implements ForegroundPresenceGateway {
  int records = 0;
  @override
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    records++;
    return DateTime.now().toUtc().add(const Duration(minutes: 30));
  }

  @override
  Future<void> stopForegroundPresence() async {}
}
