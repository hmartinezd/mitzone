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
  return Event(id:id,title:title,venue:venue,timeLabel:v['timeLabel'] as String? ?? 'Date to be announced',category:cats.isEmpty?'Event':cats.first,description:v['description'] as String? ?? 'A public gathering nearby.',locationLabel:v['locationLabel'] as String?,imageKey:v['imageUrl'] as String?,source:v['source'] as String? ?? 'ticketmaster',sourceUrl:v['sourceUrl'] as String?,imageAttribution:v['imageAttribution'] as String?,startsAt:dt(v['startsAt']),endsAt:dt(v['endsAt']));
}
