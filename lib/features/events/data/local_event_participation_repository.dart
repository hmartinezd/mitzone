import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../domain/event_participation_repository.dart';

class LocalEventParticipationRepository
    implements EventParticipationRepository {
  const LocalEventParticipationRepository(this._storage);

  static const _keyPrefix = 'local_event_participation.v1.';
  final LocalStorage _storage;

  String _key(String identityId) => '$_keyPrefix$identityId';

  @override
  Future<Set<String>> getJoinedEventIds(String identityId) async {
    final value = await _storage.getString(_key(identityId));
    if (value == null) return <String>{};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return <String>{};
      return decoded
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } on FormatException {
      return <String>{};
    }
  }

  Future<void> _write(String identityId, Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _storage.setString(_key(identityId), jsonEncode(sorted));
  }

  @override
  Future<bool> isJoined({
    required String identityId,
    required String eventId,
  }) async => (await getJoinedEventIds(identityId)).contains(eventId);

  @override
  Future<void> join({
    required String identityId,
    required String eventId,
  }) async {
    eventId = eventId.trim();
    if (eventId.isEmpty) return;
    final ids = await getJoinedEventIds(identityId);
    if (ids.add(eventId)) await _write(identityId, ids);
  }

  @override
  Future<void> leave({
    required String identityId,
    required String eventId,
  }) async {
    eventId = eventId.trim();
    if (eventId.isEmpty) return;
    final ids = await getJoinedEventIds(identityId);
    if (ids.remove(eventId)) await _write(identityId, ids);
  }
}
