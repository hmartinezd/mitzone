import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/device_token_repository.dart';
import 'supabase_device_token_repository.dart';

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository?>((ref) {
  if (ref.watch(authRepositoryProvider) == null) return null;
  return SupabaseDeviceTokenRepository(Supabase.instance.client);
});
