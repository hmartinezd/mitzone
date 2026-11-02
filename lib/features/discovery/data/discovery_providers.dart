import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discovery_item.dart';
import '../domain/discovery_repository.dart';
import 'demo_discovery_repository.dart';
import 'google_discovery_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import 'discovery_location_provider.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? GoogleDiscoveryRepository(Supabase.instance.client)
      : const DemoDiscoveryRepository(),
);

final nearbyDiscoveryProvider = FutureProvider.autoDispose
    .family<List<DiscoveryItem>, Set<String>>((ref, interests) async {
      final repository = ref.watch(discoveryRepositoryProvider);
      if (!ref.watch(productionModeProvider)) {
        return repository.getNearby(interests: interests);
      }
      final location = await ref.watch(discoveryLocationProvider.future);
      return repository
          .getNearby(
            interests: interests,
            latitude: location.latitude,
            longitude: location.longitude,
          )
          .timeout(discoveryRequestTimeout);
    }, retry: (_, _) => null);
