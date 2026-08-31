import 'dart:convert';
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
    try {
      final v = jsonDecode(await storage.getString(key(id)) ?? '[]');
      return v is List ? v.whereType<String>().toSet() : {};
    } catch (_) {
      return {};
    }
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
    final v = await _read(blockerUserId);
    v.add(blockedUserId);
    await _write(blockerUserId, v);
  }

  @override
  Future<void> unblock({
    required String blockerUserId,
    required String blockedUserId,
  }) async {
    final v = await _read(blockerUserId);
    v.remove(blockedUserId);
    await _write(blockerUserId, v);
  }

  @override
  Future<List<String>> getBlocked(String id) async =>
      (await _read(id)).toList();
}
