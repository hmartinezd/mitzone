import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/discovery_item.dart';
import '../domain/discovery_repository.dart';
import '../domain/discovery_ranking.dart';

const discoveryRadiusMeters = 2500.0;
const discoveryMaxResults = 10;

class GoogleDiscoveryRepository implements DiscoveryRepository {
  const GoogleDiscoveryRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<DiscoveryItem>> getNearby({
    Set<String> interests = const {},
    double? latitude,
    double? longitude,
    DateTime? now,
  }) async {
    if (latitude == null || longitude == null) return const [];
    final response = await client.functions.invoke(
      'nearby-discovery',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': discoveryRadiusMeters,
        'maxResults': discoveryMaxResults,
      },
    );
    final data = response.data;
    if (data is! Map || data['items'] is! List) return const [];
    final items = <DiscoveryItem>[];
    for (final value in data['items'] as List) {
      if (value is! Map) continue;
      final item = _parse(value);
      if (item != null) items.add(item);
    }
    return rankDiscoveryItems(items, interests: interests, now: now);
  }

  DiscoveryItem? _parse(Map value) {
    final id = value['id'];
    final title = value['title'];
    final categories = value['categories'];
    if (id is! String || title is! String || categories is! List) return null;
    return DiscoveryItem(
      id: id,
      source: 'google-places',
      type: DiscoveryItemType.place,
      title: title,
      category: categories.whereType<String>().toList(),
      context: value['context'] as String?,
      distanceKm: (value['distanceKm'] as num?)?.toDouble(),
    );
  }
}
