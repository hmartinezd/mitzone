import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/auth/auth_providers.dart';

final encounterProfileProvider = Provider.family<UserProfile, String>(
  (ref, id) {
    if (ref.watch(productionModeProvider)) {
      return UserProfile(
        id: id,
        displayName: 'Connection',
        bio: '',
        city: '',
        languages: const [],
        interests: const [],
        connectionGoal: ConnectionGoal.both,
      );
    }
    return ref.watch(mockIdentityRepositoryProvider).users.firstWhere(
      (user) => user.id == id,
    );
  },
);

final encounterEventProvider = Provider.family<Event?, String>(
  (ref, id) => ref.watch(eventCatalogProvider).getById(id),
);
