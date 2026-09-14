import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discovery_item.dart';
import '../domain/discovery_repository.dart';
import 'demo_discovery_repository.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (_) => const DemoDiscoveryRepository(),
);

final nearbyDiscoveryProvider = FutureProvider.family<List<DiscoveryItem>, Set<String>>(
  (ref, interests) => ref.watch(discoveryRepositoryProvider).getNearby(interests: interests),
);
