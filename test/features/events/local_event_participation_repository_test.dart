import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/events/data/local_event_participation_repository.dart';

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
  late LocalEventParticipationRepository repository;

  setUp(() {
    storage = MemoryStorage();
    repository = LocalEventParticipationRepository(storage);
  });

  test(
    'starts empty, joins idempotently, reloads, and leaves idempotently',
    () async {
      expect(await repository.getJoinedEventIds('a'), isEmpty);
      await repository.join(identityId: 'a', eventId: 'one');
      await repository.join(identityId: 'a', eventId: 'one');
      expect(await repository.getJoinedEventIds('a'), {'one'});

      final reloaded = LocalEventParticipationRepository(storage);
      expect(await reloaded.isJoined(identityId: 'a', eventId: 'one'), isTrue);
      await reloaded.leave(identityId: 'a', eventId: 'one');
      await reloaded.leave(identityId: 'a', eventId: 'one');
      expect(await reloaded.getJoinedEventIds('a'), isEmpty);
    },
  );

  test('supports multiple events and isolates identities', () async {
    await repository.join(identityId: 'a', eventId: 'one');
    await repository.join(identityId: 'a', eventId: 'two');
    await repository.join(identityId: 'b', eventId: 'three');
    expect(await repository.getJoinedEventIds('a'), {'one', 'two'});
    expect(await repository.getJoinedEventIds('b'), {'three'});
  });

  test('malformed and wrong-shaped data safely resolve empty', () async {
    storage.values['local_event_participation.v1.a'] = 'not json';
    expect(await repository.getJoinedEventIds('a'), isEmpty);
    storage.values['local_event_participation.v1.a'] = '{"id":"one"}';
    expect(await repository.getJoinedEventIds('a'), isEmpty);
    storage.values['local_event_participation.v1.a'] = '["one", 2]';
    expect(await repository.getJoinedEventIds('a'), isEmpty);
  });

  test('deduplicates persisted values and writes deterministically', () async {
    storage.values['local_event_participation.v1.a'] = '["two","one","one"]';
    expect(await repository.getJoinedEventIds('a'), {'one', 'two'});
    await repository.join(identityId: 'a', eventId: 'three');
    expect(
      storage.values['local_event_participation.v1.a'],
      '["one","three","two"]',
    );
  });
}
