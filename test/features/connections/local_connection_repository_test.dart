import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/connections/data/local_connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection_request.dart';

void main() {
  late MemoryStorage storage;
  late LocalConnectionRepository repository;

  setUp(() {
    storage = MemoryStorage();
    repository = LocalConnectionRepository(
      storage,
      now: () => DateTime.utc(2026, 8, 27),
    );
  });

  test('rejects self requests and requests without an encounter', () async {
    await expectLater(
      repository.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'a',
        encounterId: 'encounter',
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: '',
      ),
      throwsArgumentError,
    );
  });

  test(
    'logical duplicate is idempotent and exposes both pending states',
    () async {
      final first = await repository.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter-1',
        contextId: 'event:a:b',
      );
      final duplicate = await repository.sendRequest(
        senderUserId: 'b',
        recipientUserId: 'a',
        encounterId: 'encounter-2',
        contextId: 'event:a:b',
      );
      expect(duplicate.id, first.id);
      expect((await repository.getOutgoingRequests('a')).single.id, first.id);
      expect((await repository.getIncomingRequests('b')).single.id, first.id);
      expect(
        await repository.getRelationshipState(userAId: 'a', userBId: 'b'),
        RelationshipState.outgoingPending,
      );
      expect(
        await repository.getRelationshipState(userAId: 'b', userBId: 'a'),
        RelationshipState.incomingPending,
      );
    },
  );

  test(
    'only recipient can accept and acceptance creates one connection',
    () async {
      final request = await repository.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter',
      );
      await expectLater(
        repository.acceptRequest(requestId: request.id, recipientUserId: 'a'),
        throwsStateError,
      );
      final accepted = await repository.acceptRequest(
        requestId: request.id,
        recipientUserId: 'b',
      );
      expect(accepted.status, ConnectionRequestStatus.accepted);
      expect(await repository.getConnections('a'), hasLength(1));
      expect(await repository.getConnections('b'), hasLength(1));
      expect(
        await repository.getRelationshipState(userAId: 'a', userBId: 'b'),
        RelationshipState.connected,
      );
      await expectLater(
        repository.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        throwsStateError,
      );
      expect(await repository.getConnections('a'), hasLength(1));
    },
  );

  test('decline is authorized and never creates a connection', () async {
    final request = await repository.sendRequest(
      senderUserId: 'a',
      recipientUserId: 'b',
      encounterId: 'encounter',
    );
    await expectLater(
      repository.declineRequest(requestId: request.id, recipientUserId: 'a'),
      throwsStateError,
    );
    await repository.declineRequest(
      requestId: request.id,
      recipientUserId: 'b',
    );
    expect(await repository.getConnections('a'), isEmpty);
    expect(
      await repository.getRelationshipState(userAId: 'a', userBId: 'b'),
      RelationshipState.declined,
    );
  });
}

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
