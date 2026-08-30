import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/blocking/data/local_block_repository.dart';

void main() {
  test('blocks are directional, persistent and idempotent', () async {
    final storage = MemoryStorage();
    final repo = LocalBlockRepository(storage);
    await repo.block(blockerUserId: 'a', blockedUserId: 'b');
    await repo.block(blockerUserId: 'a', blockedUserId: 'b');
    expect(await repo.isBlocked('a', 'b'), isTrue);
    expect(await repo.isBlocked('b', 'a'), isFalse);
    expect(await LocalBlockRepository(storage).getBlocked('a'), ['b']);
    await repo.unblock(blockerUserId: 'a', blockedUserId: 'b');
    expect(await repo.isBlocked('a', 'b'), isFalse);
  });
  test(
    'rejects self block',
    () async => expect(
      LocalBlockRepository(
        MemoryStorage(),
      ).block(blockerUserId: 'a', blockedUserId: 'a'),
      throwsArgumentError,
    ),
  );
}

class MemoryStorage implements LocalStorage {
  final values = <String, String>{};
  @override
  Future<String?> getString(String k) async => values[k];
  @override
  Future<void> setString(String k, String v) async => values[k] = v;
  @override
  Future<bool?> getBool(String k) async => null;
  @override
  Future<void> setBool(String k, bool v) async {}
}
