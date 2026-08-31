import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/core_providers.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'supabase_auth_repository.dart';
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.isSupabaseConfigured ? SupabaseAuthRepository(Supabase.instance.client) : null;
});
final productionModeProvider = Provider<bool>((ref) => ref.watch(authRepositoryProvider) != null);
final authSessionProvider = StreamProvider<AuthSession?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) { yield null; return; }
  yield await repo.restoreSession();
  yield* repo.sessionChanges;
});
