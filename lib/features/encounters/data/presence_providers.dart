import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/presence_repository.dart';
import 'local_presence_repository.dart';
import 'supabase_presence_repository.dart';
import 'foreground_location_sources.dart';
import '../domain/location_observation.dart';
import '../domain/presence_consent.dart';
import 'package:geolocator/geolocator.dart';
import 'foreground_presence_service.dart';

final locationObservationSourceProvider = Provider<LocationObservationSource>(
  (ref) => ref.watch(productionModeProvider)
      ? const PlatformForegroundLocationSource()
      : const DemoForegroundLocationSource(),
);

final foregroundPermissionProvider = FutureProvider<LocationPermissionState>((ref) async {
  final permission = await Geolocator.checkPermission();
  return switch (permission) {
    LocationPermission.denied => LocationPermissionState.denied,
    LocationPermission.deniedForever => LocationPermissionState.deniedForever,
    LocationPermission.whileInUse => LocationPermissionState.whileUsing,
    LocationPermission.always => LocationPermissionState.background,
    _ => LocationPermissionState.notRequested,
  };
});

final presenceRepositoryProvider = Provider<PresenceRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? SupabasePresenceRepository(Supabase.instance.client)
      : LocalPresenceRepository(ref.watch(localStorageProvider)),
);

final foregroundPresenceServiceProvider = Provider<ForegroundPresenceService?>((ref) {
  if (!ref.watch(productionModeProvider)) return null;
  return ForegroundPresenceService(
    location: ref.watch(locationObservationSourceProvider),
    presence: ref.watch(presenceRepositoryProvider) as ForegroundPresenceGateway,
  );
});
