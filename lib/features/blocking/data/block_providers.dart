import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/identity/identity_providers.dart';
import '../domain/block_repository.dart';
import 'local_block_repository.dart';
import '../../../core/auth/auth_providers.dart';
import 'supabase_block_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => ref.watch(productionModeProvider)
      ? SupabaseBlockRepository(Supabase.instance.client)
      : LocalBlockRepository(ref.watch(localStorageProvider)),
);
final blockedUsersProvider = FutureProvider<List<String>>(
  (ref) => ref
      .watch(blockRepositoryProvider)
      .getBlocked(ref.watch(mockIdentityRepositoryProvider).currentUser.id),
);
final interactionBlockedProvider =
    FutureProvider.family<bool, ({String a, String b})>(
      (ref, pair) =>
          ref.watch(blockRepositoryProvider).isPairBlocked(pair.a, pair.b),
    );
