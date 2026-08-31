import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/presence_repository.dart';
import 'local_presence_repository.dart';
import 'supabase_presence_repository.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? SupabasePresenceRepository(Supabase.instance.client)
      : LocalPresenceRepository(ref.watch(localStorageProvider)),
);
