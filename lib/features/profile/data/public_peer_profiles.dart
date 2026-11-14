import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../core/identity/identity_providers.dart';
import '../../blocking/data/block_providers.dart';
import '../domain/public_profile.dart';
import 'profile_providers.dart';
import 'profile_repository.dart';

/// Stable family key prevents a new request for an equivalent set of peers.
String publicPeerIdsKey(Iterable<String> ids) =>
    (ids.where((id) => id.isNotEmpty).toSet().toList()..sort()).join(',');

/// Uses the existing server-authorized public projection, never private profiles.
/// Session/block changes invalidate the result; no identity is retained on error.
final publicPeerProfilesProvider = FutureProvider.autoDispose
    .family<Map<String, PublicProfile>, String>((ref, key) async {
      if (key.isEmpty) return {};
      final ids = key.split(',').toSet();
      final production = ref.watch(productionModeProvider);
      if (!production) {
        final users = ref.watch(mockIdentityRepositoryProvider).users;
        return {
          for (final user in users.where((user) => ids.contains(user.id)))
            user.id: PublicProfile(
              id: user.id,
              displayName: user.displayName,
              avatarUri: user.avatarUri,
            ),
        };
      }
      final userId = await ref.watch(currentUserIdProvider.future);
      if (userId.isEmpty) return {};
      final blocked = await ref.watch(blockedUsersProvider.future);
      ids.removeAll(blocked);
      return ref.watch(profileRepositoryProvider).getPublicProfilesByIds(ids);
    });

String peerProfileLabel(
  AsyncValue<Map<String, PublicProfile>> profiles,
  String id,
) {
  if (profiles.isLoading) return 'Loading name…';
  if (profiles.hasError) return 'Name unavailable';
  final name = profiles.value?[id]?.displayName.trim();
  return name == null || name.isEmpty ? 'Name unavailable' : name;
}
