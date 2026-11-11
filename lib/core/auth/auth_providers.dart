import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/core_providers.dart';
import 'auth_models.dart';
import 'password_recovery.dart';
import 'auth_repository.dart';
import 'supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isSupabaseConfigured) return null;
  final repository = SupabaseAuthRepository(Supabase.instance.client);
  final links = AppLinks();
  repository.startLinkHandling(
    links: links.uriLinkStream,
    initialLink: links.getInitialLink,
  );
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});
final passwordRecoveryStateProvider = StreamProvider<PasswordRecoveryState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  if (repository is PasswordRecoveryRepository) {
    return (repository as PasswordRecoveryRepository).passwordRecoveryStates;
  }
  return Stream.value(PasswordRecoveryState.idle);
});
final passwordRecoveryEventProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider)?.recoveryEvents ??
      const Stream.empty();
});
final productionModeProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider) != null,
);
final authSessionProvider = StreamProvider<AuthSession?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) {
    yield null;
    return;
  }
  yield await repo.restoreSession();
  yield* repo.sessionChanges;
});
