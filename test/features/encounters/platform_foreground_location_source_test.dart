import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';

class _Platform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requested = LocationPermission.whileInUse;
  int requests = 0;
  int observations = 0;
  int cachedReads = 0;
  int streams = 0;
  Object? error;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    observations++;
    settings = locationSettings;
    if (error != null) throw error!;
    return Position(
      latitude: 12,
      longitude: 34,
      timestamp: DateTime.utc(2026, 11, 5),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    cachedReads++;
    throw StateError('A stale cache is not a current fix');
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streams++;
    throw StateError('No background or persistent stream is allowed');
  }
}

Matcher _failure(ForegroundLocationFailure value) =>
    isA<ForegroundLocationException>().having(
      (error) => error.failure,
      'failure',
      value,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform original;
  late _Platform platform;
  const source = PlatformForegroundLocationSource();
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = _Platform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() {
    GeolocatorPlatform.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'Android asks fused provider for one bounded high-accuracy fix, not cache or stream',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final observed = await source.observeForeground();
      expect(platform.observations, 1);
      expect(platform.settings, isA<AndroidSettings>());
      final settings = platform.settings! as AndroidSettings;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.intervalDuration, const Duration(seconds: 1));
      expect(settings.timeLimit, const Duration(seconds: 15));
      expect(settings.forceLocationManager, isFalse);
      expect(settings.foregroundNotificationConfig, isNull);
      expect(observed.observedAt.isUtc, isTrue);
      expect(platform.cachedReads, 0);
      expect(platform.streams, 0);
    },
  );

  test('iOS preserves existing medium one-shot accuracy and timeout', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await source.observeForeground();
    expect(platform.settings, isNot(isA<AndroidSettings>()));
    expect(platform.settings!.accuracy, LocationAccuracy.medium);
    expect(platform.settings!.timeLimit, const Duration(seconds: 15));
  });

  test('disabled services do not observe or request permission', () async {
    platform.enabled = false;
    await expectLater(
      source.observeForeground(),
      throwsA(_failure(ForegroundLocationFailure.servicesDisabled)),
    );
    expect(platform.observations, 0);
    expect(platform.requests, 0);
  });

  test('permanent denial does not re-request or observe', () async {
    platform.permission = LocationPermission.deniedForever;
    await expectLater(
      source.observeForeground(),
      throwsA(_failure(ForegroundLocationFailure.permissionPermanentlyDenied)),
    );
    expect(platform.observations, 0);
    expect(platform.requests, 0);
  });

  test(
    'initial denial requests once but a declined prompt never observes',
    () async {
      platform.permission = LocationPermission.denied;
      platform.requested = LocationPermission.denied;
      await expectLater(
        source.observeForeground(),
        throwsA(_failure(ForegroundLocationFailure.permissionDenied)),
      );
      expect(platform.requests, 1);
      expect(platform.observations, 0);
    },
  );

  test(
    'background permission alone does not authorize the foreground contract',
    () async {
      platform.permission = LocationPermission.always;
      await expectLater(
        source.observeForeground(),
        throwsA(_failure(ForegroundLocationFailure.permissionDenied)),
      );
      expect(platform.observations, 0);
    },
  );

  for (final error in [
    TimeoutException('no fix'),
    PlatformException(code: 'ERROR_WHILE_ACQUIRING_POSITION'),
  ]) {
    test(
      '${error.runtimeType} stays unavailable without last-known or fabricated fallback',
      () async {
        platform.error = error;
        await expectLater(
          source.observeForeground(),
          throwsA(_failure(ForegroundLocationFailure.temporarilyUnavailable)),
        );
        expect(platform.observations, 1);
        expect(platform.cachedReads, 0);
        expect(platform.streams, 0);
      },
    );
  }
}
