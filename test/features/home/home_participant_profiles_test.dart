import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/chat/domain/chat_models.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

class _Profiles implements ProfileRepository, PublicProfileRepository {
  Set<String> requested = {};
  bool denied = false;
  @override
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(
    Set<String> ids,
  ) async {
    requested = ids;
    if (denied) throw StateError('Not authorized');
    return {
      if (ids.contains('peer'))
        'peer': const PublicProfile(id: 'peer', displayName: 'Authorized name'),
    };
  }

  // Any accidental full/private profile lookup fails the test.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Private profile access forbidden');
}

void main() {
  for (final denied in [false, true]) {
    test(
      'public participant projection; denied=$denied remains anonymous',
      () async {
        final repository = _Profiles()..denied = denied;
        final container = ProviderContainer(
          overrides: [
            productionModeProvider.overrideWithValue(true),
            currentUserIdProvider.overrideWithValue(const AsyncData('me')),
            encountersForCurrentUserProvider.overrideWithValue(
              const AsyncData([]),
            ),
            chatConversationsProvider.overrideWithValue(
              AsyncData([
                Conversation(
                  id: 'c',
                  connectionId: 'connection',
                  userAId: 'me',
                  userBId: 'peer',
                  createdAt: DateTime.utc(2026),
                ),
                Conversation(
                  id: 'c2',
                  connectionId: 'connection2',
                  userAId: 'missing',
                  userBId: 'me',
                  createdAt: DateTime.utc(2026),
                ),
              ]),
            ),
            profileRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final profiles = await container.read(
          homeParticipantProfilesProvider.future,
        );
        expect(repository.requested, {'peer', 'missing'});
        expect(
          profiles.map((p) => p.displayName),
          denied ? isEmpty : ['Authorized name'],
        );
      },
    );
  }
  test('empty social state performs no profile lookup', () async {
    final repository = _Profiles();
    final container = ProviderContainer(
      overrides: [
        productionModeProvider.overrideWithValue(true),
        currentUserIdProvider.overrideWithValue(const AsyncData('me')),
        encountersForCurrentUserProvider.overrideWithValue(const AsyncData([])),
        chatConversationsProvider.overrideWithValue(const AsyncData([])),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    expect(
      await container.read(homeParticipantProfilesProvider.future),
      isEmpty,
    );
    expect(repository.requested, isEmpty);
  });
}
