import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../domain/event_check_in.dart';
import '../domain/event_check_in_repository.dart';

class LocalEventCheckInRepository implements EventCheckInRepository {
  const LocalEventCheckInRepository(this._storage);

  static const keyPrefix = 'local_event_check_in.v1.';
  final LocalStorage _storage;

  String _key(String identityId) => '$keyPrefix$identityId';

  @override
  Future<List<EventCheckIn>> getCheckIns(String identityId) async {
    final value = await _storage.getString(_key(identityId));
    if (value == null) return <EventCheckIn>[];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return <EventCheckIn>[];
      final byEvent = <String, EventCheckIn>{};
      for (final value in decoded) {
        final checkIn = _decode(value, identityId);
        if (checkIn == null) continue;
        final existing = byEvent[checkIn.eventId];
        if (existing == null ||
            checkIn.checkedInAt.isBefore(existing.checkedInAt)) {
          byEvent[checkIn.eventId] = checkIn;
        }
      }
      final result = byEvent.values.toList()
        ..sort((a, b) => a.eventId.compareTo(b.eventId));
      return result;
    } on FormatException {
      return <EventCheckIn>[];
    }
  }

  EventCheckIn? _decode(Object? value, String identityId) {
    if (value is! Map) return null;
    final eventId = value['eventId'];
    final timestamp = value['checkedInAt'];
    final method = value['method'];
    final checkedOutAt = value['checkedOutAt'];
    if (eventId is! String || timestamp is! String || method is! String) {
      return null;
    }
    final normalizedEventId = eventId.trim();
    final parsedTimestamp = DateTime.tryParse(timestamp);
    final parsedMethod = switch (method) {
      'manual' => EventCheckInMethod.manual,
      'localDemo' => EventCheckInMethod.localDemo,
      _ => null,
    };
    if (normalizedEventId.isEmpty ||
        parsedTimestamp == null ||
        parsedMethod == null) {
      return null;
    }
    return EventCheckIn(
      eventId: normalizedEventId,
      identityId: identityId,
      checkedInAt: parsedTimestamp.toUtc(),
      checkedOutAt: checkedOutAt is String ? DateTime.tryParse(checkedOutAt)?.toUtc() : null,
      method: parsedMethod,
    );
  }

  @override
  Future<EventCheckIn?> getCheckIn({
    required String identityId,
    required String eventId,
  }) async {
    final normalized = eventId.trim();
    if (normalized.isEmpty) return null;
    for (final checkIn in await getCheckIns(identityId)) {
      if (checkIn.eventId == normalized) return checkIn;
    }
    return null;
  }

  @override
  Future<void> recordCheckIn(EventCheckIn checkIn) async {
    final identityId = checkIn.identityId.trim();
    final eventId = checkIn.eventId.trim();
    if (identityId.isEmpty || eventId.isEmpty) return;
    final records = await getCheckIns(identityId);
    if (records.any((record) => record.eventId == eventId)) return;
    records.add(
      EventCheckIn(
        eventId: eventId,
        identityId: identityId,
        checkedInAt: checkIn.checkedInAt.toUtc(),
        method: checkIn.method,
      ),
    );
    records.sort((a, b) => a.eventId.compareTo(b.eventId));
    await _storage.setString(
      _key(identityId),
      jsonEncode([
        for (final record in records)
          {
            'eventId': record.eventId,
            'checkedInAt': record.checkedInAt.toUtc().toIso8601String(),
            if (record.checkedOutAt != null) 'checkedOutAt': record.checkedOutAt!.toUtc().toIso8601String(),
            'method': record.method.name,
          },
      ]),
    );
  }
}
