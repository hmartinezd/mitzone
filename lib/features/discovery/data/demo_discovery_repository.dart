import '../../events/data/demo_events.dart';
import '../../events/domain/event.dart';
import '../domain/discovery_item.dart';
import '../domain/discovery_repository.dart';
import '../domain/discovery_ranking.dart';

class DemoDiscoveryRepository implements DiscoveryRepository {
  const DemoDiscoveryRepository();

  @override
  Future<List<DiscoveryItem>> getNearby({
    Set<String> interests = const {},
    double? latitude,
    double? longitude,
    DateTime? now,
  }) async => rankDiscoveryItems(
    nearbyDemoEvents.map(_fromEvent),
    interests: interests,
    now: now,
  );

  static DiscoveryItem _fromEvent(Event event) => DiscoveryItem(
    id: event.id,
    source: 'demo-events',
    type: DiscoveryItemType.activity,
    title: event.title,
    category: [event.category],
    imageReference: event.imageKey,
    context: event.locationLabel,
    subtitle: event.timeLabel,
  );
}
