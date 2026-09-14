import 'discovery_item.dart';

const discoveryInterestWeight = 0.5;
const discoveryProximityWeight = 0.3;
const discoveryMomentWeight = 0.2;

List<DiscoveryItem> rankDiscoveryItems(
  Iterable<DiscoveryItem> items, {
  Set<String> interests = const {},
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  final normalized = interests.map(normalizeDiscoveryTag).toSet();
  final active = items.where((item) => !_isExpired(item, moment)).toList();
  active.sort((a, b) {
    final score = _score(b, normalized, moment).compareTo(_score(a, normalized, moment));
    return score == 0 ? a.id.compareTo(b.id) : score;
  });
  return active;
}

double _score(DiscoveryItem item, Set<String> interests, DateTime now) {
  final interest = item.category.map(normalizeDiscoveryTag).where(interests.contains).isNotEmpty ? 1.0 : 0.0;
  final proximity = item.distanceKm == null ? 0.5 : (1 / (1 + item.distanceKm!)).clamp(0.0, 1.0);
  final moment = item.startsAt == null ? 0.7 : (1 / (1 + item.startsAt!.difference(now).inHours.abs())).clamp(0.0, 1.0);
  return interest * discoveryInterestWeight + proximity * discoveryProximityWeight + moment * discoveryMomentWeight;
}

bool _isExpired(DiscoveryItem item, DateTime now) =>
    item.type == DiscoveryItemType.activity && item.endsAt != null && item.endsAt!.isBefore(now);

String normalizeDiscoveryTag(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('-', ' ');
  const aliases = {
    'soccer': 'sports', 'football': 'sports', 'concert': 'music',
    'live music': 'music', 'restaurant': 'food', 'food market': 'food',
    'food festival': 'food', 'museum': 'art', 'exhibition': 'art',
    'park': 'outdoors', 'hiking': 'outdoors', 'outdoor activity': 'outdoors',
  };
  return aliases[normalized] ?? normalized;
}
