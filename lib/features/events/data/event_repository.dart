import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/event.dart';

abstract interface class EventRepository { Future<List<Event>> getNearby({required double latitude, required double longitude}); }
class SupabaseEventRepository implements EventRepository {
  const SupabaseEventRepository(this.client); final SupabaseClient client;
  @override Future<List<Event>> getNearby({required double latitude, required double longitude}) async {
    final response = await client.functions.invoke('nearby-events', body: {'latitude': latitude, 'longitude': longitude});
    final data = response.data;
    if (data is! Map || data['events'] is! List) return const [];
    return (data['events'] as List).whereType<Map>().map(normalizeExternalEvent).whereType<Event>().toList();
  }
}
Event? normalizeExternalEvent(Map v) {
  final id=v['id'], title=v['title'], venue=v['venue'];
  if (id is! String || title is! String || venue is! String || id.trim().isEmpty) return null;
  final cats=(v['categories'] as List?)?.whereType<String>().toList() ?? const <String>[];
  DateTime? dt(Object? x)=>x is String ? DateTime.tryParse(x) : null;
  final startRaw = v['startsAt'];
  final endRaw = v['endsAt'];
  final startsAt = dt(startRaw);
  final endsAt = dt(endRaw);
  return Event(id:id,title:title,venue:venue,timeLabel:formatProviderEventTime(startRaw, endRaw),category:cats.isEmpty?'Event':cats.first,description:v['description'] as String? ?? 'A public gathering nearby.',locationLabel:v['locationLabel'] as String?,imageKey:v['imageUrl'] as String?,source:v['source'] as String? ?? 'ticketmaster',sourceUrl:v['sourceUrl'] as String?,imageAttribution:v['imageAttribution'] as String?,startsAt:startsAt,endsAt:endsAt);
}

String formatProviderEventTime(Object? startValue, Object? endValue) {
  if (startValue is! String) return 'Date to be announced';
  final start = DateTime.tryParse(startValue)?.toLocal();
  if (start == null) return 'Date to be announced';
  final date = '${start.month}/${start.day}/${start.year}';
  final hasTime = startValue.contains('T');
  if (!hasTime) return date;
  String clock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${value.minute.toString().padLeft(2, '0')} $suffix';
  }
  final result = '$date at ${clock(start)}';
  final end = endValue is String ? DateTime.tryParse(endValue)?.toLocal() : null;
  return end == null ? result : '$result – ${clock(end)}';
}
