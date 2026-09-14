import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discovery_item.dart';
import '../domain/discovery_repository.dart';
import 'demo_discovery_repository.dart';
import 'google_discovery_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../encounters/data/presence_providers.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? GoogleDiscoveryRepository(Supabase.instance.client)
      : const DemoDiscoveryRepository(),
);

final nearbyDiscoveryProvider = FutureProvider.family<List<DiscoveryItem>, Set<String>>(
  (ref, interests) async {
    final repository = ref.watch(discoveryRepositoryProvider);
    if (!ref.watch(productionModeProvider)) {
      return repository.getNearby(interests: interests);
    }
    try {
      final location = await ref
          .read(locationObservationSourceProvider)
          .observeForeground();
      return await repository.getNearby(
        interests: interests,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      return const DemoDiscoveryRepository().getNearby();
    }
  },
);
