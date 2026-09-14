import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/discovery/data/demo_discovery_repository.dart';
import 'package:mitzone/features/discovery/domain/discovery_item.dart';
import 'package:mitzone/features/discovery/domain/discovery_ranking.dart';

void main() {
  test('demo repository returns normalized discovery items', () async {
    final items = await const DemoDiscoveryRepository().getNearby();
    expect(items, isNotEmpty);
    expect(items.every((item) => item.source == 'demo-events'), isTrue);
  });

  test('interest and proximity produce deterministic ranking', () {
    final items = [
      const DiscoveryItem(
        id: 'far-match',
        source: 'test',
        type: DiscoveryItemType.place,
        title: 'Far music place',
        category: ['music'],
        distanceKm: 10,
      ),
      const DiscoveryItem(
        id: 'near-match',
        source: 'test',
        type: DiscoveryItemType.place,
        title: 'Near music place',
        category: ['music'],
        distanceKm: 1,
      ),
    ];
    final ranked = rankDiscoveryItems(items, interests: {'music'});
    expect(ranked.first.id, 'near-match');
    expect(ranked.map((item) => item.id).toList(), ['near-match', 'far-match']);
  });

  test('expired activities are excluded and places need no time', () {
    final now = DateTime(2026, 1, 1);
    final ranked = rankDiscoveryItems([
      DiscoveryItem(
        id: 'expired',
        source: 'test',
        type: DiscoveryItemType.activity,
        title: 'Old activity',
        category: const ['music'],
        endsAt: now.subtract(const Duration(minutes: 1)),
      ),
      const DiscoveryItem(
        id: 'place',
        source: 'test',
        type: DiscoveryItemType.place,
        title: 'Coffee shop',
        category: ['food'],
      ),
    ], now: now);
    expect(ranked.map((item) => item.id), ['place']);
  });
}
