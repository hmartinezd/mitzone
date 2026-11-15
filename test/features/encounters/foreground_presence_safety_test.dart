import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_preferences.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_refresher.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_service.dart';
import 'package:mitzone/features/encounters/data/presence_providers.dart';
import 'package:mitzone/features/encounters/domain/foreground_presence_controller.dart';
import 'package:mitzone/features/encounters/domain/location_observation.dart';
import 'package:mitzone/features/encounters/presentation/foreground_presence_card.dart';

import '../../support/memory_local_storage.dart';

class _Location implements LocationObservationSource {
  int calls = 0;
  Completer<LocationObservation>? pending;
  @override
  Future<LocationObservation> observeForeground() async {
    calls++;
    return pending?.future ??
        Future.value(
          LocationObservation(
            latitude: 12,
            longitude: 34,
            observedAt: DateTime.now().toUtc(),
          ),
        );
  }
}

class _Gateway
    implements ForegroundPresenceGateway, ForegroundPresenceRefreshGateway {
  int records = 0;
  int stops = 0;
  bool failStop = false;
  Completer<void>? pendingStop;
  Completer<DateTime>? pendingRecord;
  final order = <String>[];
  @override
  Future<DateTime> refreshForegroundPresence({
    required double latitude,
    required double longitude,
  }) => recordForegroundPresence(latitude: latitude, longitude: longitude);
  @override
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    records++;
    final expiry =
        await (pendingRecord?.future ??
            Future.value(
              DateTime.now().toUtc().add(const Duration(minutes: 30)),
            ));
    order.add('record');
    return expiry;
  }

  @override
  Future<void> stopForegroundPresence() async {
    stops++;
    await pendingStop?.future;
    if (failStop) throw StateError('offline');
    order.add('stop');
  }
}

final _account = StateProvider<String>((ref) => 'account-a');

Widget _app(
  MemoryLocalStorage storage,
  ForegroundPresenceService service, {
  bool visible = true,
}) => ProviderScope(
  overrides: [
    productionModeProvider.overrideWithValue(true),
    currentUserIdProvider.overrideWith((ref) async => ref.watch(_account)),
    localStorageProvider.overrideWithValue(storage),
    foregroundPresenceServiceProvider.overrideWithValue(service),
    encountersForCurrentUserProvider.overrideWithValue(
      const AsyncValue.data([]),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TickerMode(
          enabled: visible,
          child: const ForegroundPresenceCard(),
        ),
      ),
    ),
  ),
);

Future<void> _activate(WidgetTester tester) async {
  await tester.tap(find.text('Activate presence'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'consent and recorded expiry are scoped to one account; legacy consent is ignored',
    () async {
      final storage = MemoryLocalStorage();
      await storage.setBool('foreground_presence_consent.v1', true);
      final a = ForegroundPresencePreferences(storage, 'a');
      final b = ForegroundPresencePreferences(storage, 'b');
      expect(await a.hasConsent(), isFalse);
      expect(await b.hasConsent(), isFalse);
      await a.saveConsent();
      final expiry = DateTime.utc(2026, 11, 4, 12);
      await a.saveExpiry(expiry);
      expect(await a.hasConsent(), isTrue);
      expect(await b.hasConsent(), isFalse);
      expect(await b.lastExpiry(), isNull);
      expect(await a.lastExpiry(), expiry);
      await a.saveExpiry(null);
      expect(await a.lastExpiry(), isNull);
    },
  );

  test(
    'account authorization is checked after pending location before any write',
    () async {
      final location = _Location()..pending = Completer<LocationObservation>();
      final gateway = _Gateway();
      final service = ForegroundPresenceService(
        location: location,
        presence: gateway,
      );
      bool authorized = true;
      final record = service.record(
        consent: true,
        isStillAuthorized: () => authorized,
      );
      authorized = false;
      location.pending!.complete(
        LocationObservation(
          latitude: 1,
          longitude: 2,
          observedAt: DateTime.now().toUtc(),
        ),
      );
      expect(await record, ForegroundPresenceStatus.denied);
      expect(gateway.records, 0);
    },
  );

  test('Stop cancels an unresolved observation before write', () async {
    final location = _Location()..pending = Completer<LocationObservation>();
    final gateway = _Gateway();
    final service = ForegroundPresenceService(
      location: location,
      presence: gateway,
    );
    final record = service.record(consent: true);
    await service.stop();
    location.pending!.complete(
      LocationObservation(
        latitude: 1,
        longitude: 2,
        observedAt: DateTime.now().toUtc(),
      ),
    );
    expect(await record, ForegroundPresenceStatus.denied);
    expect(gateway.records, 0);
    expect(gateway.stops, 1);
  });

  test('Stop is ordered after an already submitted record', () async {
    final gateway = _Gateway()..pendingRecord = Completer<DateTime>();
    final service = ForegroundPresenceService(
      location: _Location(),
      presence: gateway,
    );
    final record = service.record(consent: true);
    await Future<void>.delayed(Duration.zero);
    final stop = service.stop();
    expect(gateway.stops, 0);
    gateway.pendingRecord!.complete(
      DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    await record;
    await stop;
    expect(gateway.order, ['record', 'stop']);
    expect(service.expiresAt, isNull);
  });

  testWidgets(
    'failed Stop stays visible; pending Stop blocks duplicate requests; success restores activation',
    (tester) async {
      final storage = MemoryLocalStorage();
      final gateway = _Gateway();
      final service = ForegroundPresenceService(
        location: _Location(),
        presence: gateway,
      );
      await tester.pumpWidget(_app(storage, service));
      await tester.pumpAndSettle();
      await _activate(tester);
      expect(gateway.records, 1);
      gateway.failStop = true;
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t confirm Stop'), findsOneWidget);
      expect(find.text('Presence stopped.'), findsNothing);
      gateway.failStop = false;
      gateway.pendingStop = Completer<void>();
      await tester.tap(find.text('Retry Stop'));
      await tester.pump();
      expect(find.text('Stopping…'), findsOneWidget);
      await tester.tap(find.text('Stopping…'));
      await tester.pump();
      expect(gateway.stops, 2);
      gateway.pendingStop!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Presence stopped.'), findsOneWidget);
      expect(find.text('Activate presence'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'restored unexpired account record exposes Stop without automatically collecting again',
    (tester) async {
      final storage = MemoryLocalStorage();
      final preferences = ForegroundPresencePreferences(storage, 'account-a');
      await preferences.saveConsent();
      await preferences.saveExpiry(
        DateTime.now().toUtc().add(const Duration(minutes: 20)),
      );
      final location = _Location();
      await tester.pumpWidget(
        _app(
          storage,
          ForegroundPresenceService(location: location, presence: _Gateway()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Resume presence'), findsOneWidget);
      final stop = find
          .ancestor(
            of: find.text('Stop'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          )
          .first;
      final button = tester.widget<FilledButton>(stop);
      final theme = Theme.of(tester.element(stop));
      expect(
        button.style!.backgroundColor!.resolve({}),
        theme.colorScheme.error,
      );
      expect(tester.getSize(stop).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(stop).width, greaterThan(300));
      await tester.pump(const Duration(minutes: 2));
      expect(location.calls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('account switch requires independent consent', (tester) async {
    final storage = MemoryLocalStorage();
    await ForegroundPresencePreferences(storage, 'account-a').saveConsent();
    final gateway = _Gateway();
    await tester.pumpWidget(
      _app(
        storage,
        ForegroundPresenceService(location: _Location(), presence: gateway),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ForegroundPresenceCard)),
    );
    container.read(_account.notifier).state = 'account-b';
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activate presence'));
    await tester.pumpAndSettle();
    expect(find.text('Choose to be discoverable'), findsOneWidget);
    expect(gateway.records, 0);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'bounded refresher stops at deadline and does not overlap slow observations',
    (tester) async {
      var now = DateTime.utc(2026);
      final deadline = now.add(const Duration(minutes: 2));
      final pending = Completer<void>();
      int calls = 0;
      final refresher = ForegroundPresenceRefresher(
        mayObserve: () => true,
        now: () => now,
        refresh: () {
          calls++;
          return pending.future;
        },
      );
      refresher.start(deadline);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
      pending.complete();
      await tester.pump();
      now = deadline;
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
      refresher.pause();
    },
  );

  testWidgets(
    'foreground refresh pauses while hidden or backgrounded and Stop prevents further observations',
    (tester) async {
      final storage = MemoryLocalStorage();
      final location = _Location();
      final gateway = _Gateway();
      final service = ForegroundPresenceService(
        location: location,
        presence: gateway,
      );
      await tester.pumpWidget(_app(storage, service));
      await tester.pumpAndSettle();
      await _activate(tester);
      await tester.pump(const Duration(seconds: 60));
      await tester.pump();
      expect(location.calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(location.calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(_app(storage, service, visible: false));
      await tester.pump(const Duration(minutes: 2));
      expect(location.calls, 2);
      await tester.pumpWidget(_app(storage, service));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2));
      expect(location.calls, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
