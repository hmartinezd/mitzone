import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import 'local_personality_repository.dart';
import 'personality_repository.dart';
import 'supabase_personality_repository.dart';

final personalityRepositoryProvider = Provider<PersonalityRepository>(
  (ref) => ref.watch(authRepositoryProvider) == null
      ? LocalPersonalityRepository(ref.watch(localStorageProvider))
      : SupabasePersonalityRepository(Supabase.instance.client),
);
final currentPersonalityProvider = FutureProvider(
  (ref) async => ref
      .watch(personalityRepositoryProvider)
      .getForUser(await ref.watch(currentUserIdProvider.future)),
);
