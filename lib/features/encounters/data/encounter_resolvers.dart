import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

final encounterProfileProvider = FutureProvider.family<PublicProfile?, String>(
  (ref, id) async {
    if (ref.watch(productionModeProvider)) {
      return ref.watch(profileRepositoryProvider).getPublicProfile(id);
    }
    final user = ref.watch(mockIdentityRepositoryProvider).users.where((u) => u.id == id).firstOrNull;
    return user == null ? null : PublicProfile(id: user.id, displayName: user.displayName, avatarUri: user.avatarUri, bio: user.bio, city: user.city);
  },
);

final encounterEventProvider = Provider.family<Event?, String>(
  (ref, id) => ref.watch(eventCatalogProvider).getById(id),
);
