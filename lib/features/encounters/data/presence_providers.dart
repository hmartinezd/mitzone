import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/presence_repository.dart';
import 'local_presence_repository.dart';
import 'supabase_presence_repository.dart';
import 'foreground_location_sources.dart';
import '../domain/location_observation.dart';
import 'foreground_presence_service.dart';

final locationObservationSourceProvider = Provider<LocationObservationSource>(
  (ref) => ref.watch(productionModeProvider)
      ? const PlatformForegroundLocationSource()
      : const DemoForegroundLocationSource(),
);

final presenceRepositoryProvider = Provider<PresenceRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? SupabasePresenceRepository(Supabase.instance.client)
      : LocalPresenceRepository(ref.watch(localStorageProvider)),
);

final foregroundPresenceGatewayProvider = Provider<ForegroundPresenceGateway>((ref) {
  if (!ref.watch(productionModeProvider)) return const DemoForegroundPresenceGateway();
  return _RepositoryForegroundGateway(ref.watch(presenceRepositoryProvider));
});
final foregroundPresenceServiceProvider = Provider<ForegroundPresenceService>((ref) {
  return ForegroundPresenceService(
    location: ref.watch(locationObservationSourceProvider),
    presence: ref.watch(foregroundPresenceGatewayProvider),
  );
});

class _RepositoryForegroundGateway implements ForegroundPresenceGateway {
  const _RepositoryForegroundGateway(this.repository);
  final PresenceRepository repository;
  @override
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude}) => repository.recordForegroundPresence(latitude: latitude, longitude: longitude);
  @override
  Future<void> stopForegroundPresence() => repository.stopForegroundPresence();
}
