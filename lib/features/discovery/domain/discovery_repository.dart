import 'discovery_item.dart';

abstract interface class DiscoveryRepository {
  Future<List<DiscoveryItem>> getNearby({
    Set<String> interests = const {},
    double? latitude,
    double? longitude,
    DateTime? now,
  });
}
