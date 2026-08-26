import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';
import 'package:mitzone/features/events/domain/event_check_in_repository.dart';
import 'package:mitzone/features/events/domain/event_participation_repository.dart';

class TestIdentityGateway implements IdentityGateway {
  @override
  Future<AppIdentity> ensureIdentity() async => const AppIdentity(
    id: 'current-identity',
    type: AppIdentityType.localDevelopment,
  );

  @override
  Future<AppIdentity?> getExistingIdentity() => ensureIdentity();
}

class JoinedRepository implements EventParticipationRepository {
  bool joined = true;

  @override
  Future<Set<String>> getJoinedEventIds(String identityId) async =>
      joined ? {'event-one'} : {};
  @override
  Future<bool> isJoined({
    required String identityId,
    required String eventId,
  }) async => joined;
  @override
  Future<void> join({
    required String identityId,
    required String eventId,
  }) async {}
  @override
  Future<void> leave({
    required String identityId,
    required String eventId,
  }) async {}
}

class RecordingRepository implements EventCheckInRepository {
  final records = <EventCheckIn>[];
  Completer<void>? blocker;
  bool fail = false;

  @override
  Future<EventCheckIn?> getCheckIn({
    required String identityId,
    required String eventId,
  }) async => records.where((record) => record.eventId == eventId).firstOrNull;
  @override
  Future<List<EventCheckIn>> getCheckIns(String identityId) async =>
      records.where((record) => record.identityId == identityId).toList();
  @override
  Future<void> recordCheckIn(EventCheckIn checkIn) async {
    if (fail) throw Exception('write failed');
    await blocker?.future;
    if (records.any((record) => record.eventId == checkIn.eventId)) return;
    records.add(checkIn);
  }
}

void main() {
  late JoinedRepository participation;
  late RecordingRepository checkIns;
  late ProviderContainer container;

  setUp(() {
    participation = JoinedRepository();
    checkIns = RecordingRepository();
    container = ProviderContainer(
      overrides: [
        identityGatewayProvider.overrideWithValue(TestIdentityGateway()),
        eventParticipationRepositoryProvider.overrideWithValue(participation),
        eventCheckInRepositoryProvider.overrideWithValue(checkIns),
        utcNowProvider.overrideWithValue(
          () => DateTime.utc(2026, 8, 21, 23, 42),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('uses current identity and injected UTC time', () async {
    final success = await container
        .read(eventCheckInControllerProvider)
        .recordLocalDemoCheckIn('event-one');
    expect(success, isTrue);
    expect(checkIns.records.single.identityId, 'current-identity');
    expect(
      checkIns.records.single.checkedInAt,
      DateTime.utc(2026, 8, 21, 23, 42),
    );
  });

  test('rejects check-in when current identity has not joined', () async {
    participation.joined = false;
    final success = await container
        .read(eventCheckInControllerProvider)
        .recordLocalDemoCheckIn('event-one');
    expect(success, isFalse);
    expect(checkIns.records, isEmpty);
  });

  test('protects against double submission', () async {
    checkIns.blocker = Completer<void>();
    final controller = container.read(eventCheckInControllerProvider);
    final first = controller.recordLocalDemoCheckIn('event-one');
    await Future<void>.delayed(Duration.zero);
    expect(await controller.recordLocalDemoCheckIn('event-one'), isFalse);
    checkIns.blocker!.complete();
    expect(await first, isTrue);
    expect(checkIns.records, hasLength(1));
  });

  test('repository failure propagates without success state', () async {
    checkIns.fail = true;
    expect(
      () => container
          .read(eventCheckInControllerProvider)
          .recordLocalDemoCheckIn('event-one'),
      throwsException,
    );
    expect(checkIns.records, isEmpty);
  });

  test('existing record remains stable', () async {
    final original = EventCheckIn(
      eventId: 'event-one',
      identityId: 'current-identity',
      checkedInAt: DateTime.utc(2026, 1, 1),
      method: EventCheckInMethod.localDemo,
    );
    checkIns.records.add(original);
    await container
        .read(eventCheckInControllerProvider)
        .recordLocalDemoCheckIn('event-one');
    expect(checkIns.records, [same(original)]);
  });
}
