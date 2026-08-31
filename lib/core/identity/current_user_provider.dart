import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';
import 'identity_providers.dart';

/// Resolves the authoritative Mitzone user ID without exposing backend types.
final currentUserIdProvider = FutureProvider<String>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (ref.watch(productionModeProvider)) {
    if (session == null) throw StateError('Authentication required');
    return session.user.id;
  }
  return ref.watch(mockIdentityRepositoryProvider).currentUser.id;
});
