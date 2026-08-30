import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/identity/identity_providers.dart';
import '../domain/block_repository.dart';
import 'local_block_repository.dart';

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => LocalBlockRepository(ref.watch(localStorageProvider)),
);
final blockedUsersProvider = FutureProvider<List<String>>(
  (ref) => ref
      .watch(blockRepositoryProvider)
      .getBlocked(ref.watch(mockIdentityRepositoryProvider).currentUser.id),
);
