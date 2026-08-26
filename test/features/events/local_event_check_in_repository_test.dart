import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/events/data/local_event_check_in_repository.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';

class MemoryStorage implements LocalStorage {
  final values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

void main() {
  late MemoryStorage storage;
  late LocalEventCheckInRepository repository;
  final first = DateTime.utc(2026, 8, 21, 23, 42);

  EventCheckIn record(String identity, String event, DateTime at) =>
      EventCheckIn(
        eventId: event,
        identityId: identity,
        checkedInAt: at,
        method: EventCheckInMethod.localDemo,
      );

  setUp(() {
    storage = MemoryStorage();
    repository = LocalEventCheckInRepository(storage);
  });

  test(
    'starts empty, persists, and survives repository reconstruction',
    () async {
      expect(await repository.getCheckIns('a'), isEmpty);
      await repository.recordCheckIn(record('a', 'event-one', first));
      final reloaded = LocalEventCheckInRepository(storage);
      final loaded = await reloaded.getCheckIn(
        identityId: 'a',
        eventId: 'event-one',
      );
      expect(loaded?.checkedInAt, first);
      expect(loaded?.method, EventCheckInMethod.localDemo);
      expect(loaded?.identityId, 'a');
    },
  );

  test('duplicate record preserves the original timestamp', () async {
    await repository.recordCheckIn(record('a', 'event-one', first));
    await repository.recordCheckIn(
      record('a', 'event-one', first.add(const Duration(days: 1))),
    );
    final records = await repository.getCheckIns('a');
    expect(records, hasLength(1));
    expect(records.single.checkedInAt, first);
  });

  test('isolates identities and ignores blank mutations', () async {
    await repository.recordCheckIn(record('a', 'one', first));
    await repository.recordCheckIn(record('b', 'two', first));
    await repository.recordCheckIn(record('a', '  ', first));
    expect((await repository.getCheckIns('a')).single.eventId, 'one');
    expect((await repository.getCheckIns('b')).single.eventId, 'two');
  });

  test('malformed JSON and unexpected root safely resolve empty', () async {
    storage.values['${LocalEventCheckInRepository.keyPrefix}a'] = 'bad';
    expect(await repository.getCheckIns('a'), isEmpty);
    storage.values['${LocalEventCheckInRepository.keyPrefix}a'] = '{}';
    expect(await repository.getCheckIns('a'), isEmpty);
  });

  test('recovers valid records from mixed malformed entries', () async {
    storage.values['${LocalEventCheckInRepository.keyPrefix}a'] = jsonEncode([
      null,
      3,
      {
        'eventId': '',
        'checkedInAt': first.toIso8601String(),
        'method': 'localDemo',
      },
      {'eventId': 'bad-time', 'checkedInAt': 'nope', 'method': 'localDemo'},
      {
        'eventId': 'bad-method',
        'checkedInAt': first.toIso8601String(),
        'method': 'verifiedQr',
      },
      {
        'eventId': ' valid ',
        'checkedInAt': first.toIso8601String(),
        'method': 'localDemo',
      },
    ]);
    final records = await repository.getCheckIns('a');
    expect(records, hasLength(1));
    expect(records.single.eventId, 'valid');
  });

  test('deduplicates persisted events using the earliest timestamp', () async {
    final later = first.add(const Duration(hours: 2));
    storage.values['${LocalEventCheckInRepository.keyPrefix}a'] = jsonEncode([
      {
        'eventId': 'two',
        'checkedInAt': later.toIso8601String(),
        'method': 'localDemo',
      },
      {
        'eventId': 'one',
        'checkedInAt': later.toIso8601String(),
        'method': 'localDemo',
      },
      {
        'eventId': 'one',
        'checkedInAt': first.toIso8601String(),
        'method': 'localDemo',
      },
    ]);
    final records = await repository.getCheckIns('a');
    expect(records.map((record) => record.eventId), ['one', 'two']);
    expect(records.first.checkedInAt, first);
  });

  test(
    'writes deterministic UTC JSON without duplicating event data',
    () async {
      await repository.recordCheckIn(record('a', 'two', first.toLocal()));
      await repository.recordCheckIn(record('a', 'one', first));
      final value = storage.values['${LocalEventCheckInRepository.keyPrefix}a'];
      expect(value, contains('"eventId":"one"'));
      expect(value, contains('"checkedInAt":"2026-08-21T23:42:00.000Z"'));
      expect(value, isNot(contains('title')));
    },
  );
}
