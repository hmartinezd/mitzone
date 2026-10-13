import 'dart:convert';
import '../../connections/data/local_relationship_transaction.dart';
import '../../connections/data/local_connection_repository.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/block_repository.dart';

class LocalBlockRepository implements BlockRepository {
  const LocalBlockRepository(this.storage);
  final LocalStorage storage;
  @override
  Future<bool> isPairBlocked(String a, String b) async =>
      await isBlocked(a, b) || await isBlocked(b, a);
  String key(String id) => 'local_blocks.v1.$id';
  Future<Set<String>> _read(String id) async {
    final raw = await storage.getString(key(id));
    if (raw == null) return {};
    final value = jsonDecode(raw);
    if (value is! List || value.any((id) => id is! String)) {
      throw StateError('Block state is unavailable');
    }
    return value.cast<String>().toSet();
  }

  Future<void> _write(String id, Set<String> values) =>
      storage.setString(key(id), jsonEncode(values.toList()..sort()));
  @override
  Future<bool> isBlocked(String a, String b) async =>
      (await _read(a)).contains(b);
  @override
  Future<void> block({
    required String blockerUserId,
    required String blockedUserId,
  }) async {
    if (blockerUserId == blockedUserId) {
      throw ArgumentError('Cannot block yourself');
    }
    await localRelationshipTransaction(storage, () async {
      final v = await _read(blockerUserId);
      v.add(blockedUserId);
      await _write(blockerUserId, v);
    });
    await LocalConnectionRepository(
      storage,
    ).terminatePair(blockerUserId, blockedUserId);
  }

  @override
  Future<void> unblock({
    required String blockerUserId,
    required String blockedUserId,
  }) async {
    if (!await isBlocked(blockerUserId, blockedUserId)) return;
    // Also invalidate legacy relationships that were only hidden by a block.
    await LocalConnectionRepository(
      storage,
    ).terminatePair(blockerUserId, blockedUserId);
    await localRelationshipTransaction(storage, () async {
      final v = await _read(blockerUserId);
      v.remove(blockedUserId);
      await _write(blockerUserId, v);
    });
  }

  @override
  Future<List<String>> getBlocked(String id) async =>
      (await _read(id)).toList();
}
