import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/blocking/data/block_providers.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/chat/domain/chat_models.dart';
import 'package:mitzone/features/chat/domain/chat_repository.dart';
import 'package:mitzone/features/chat/presentation/chat_screen.dart';
import 'package:mitzone/features/chat/presentation/conversation_screen.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/connections/domain/connection.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/data/public_peer_profiles.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/notifications/data/notification_providers.dart';

final _now = DateTime.utc(2026, 11, 12, 12, 30);
final _conversations = [
  for (final peer in ['a', 'b'])
    Conversation(
      id: 'chat-$peer',
      connectionId: 'conn-$peer',
      userAId: 'me',
      userBId: peer,
      createdAt: _now,
    ),
];
final _connections = [
  for (final peer in ['a', 'b'])
    Connection(
      id: 'conn-$peer',
      userAId: 'me',
      userBId: peer,
      encounterId: 'enc-$peer',
      connectedAt: _now,
    ),
];
const _profiles = {
  'a': PublicProfile(id: 'a', displayName: 'Sofia'),
  'b': PublicProfile(id: 'b', displayName: 'Daniel'),
};

Widget _fixture(
  Widget screen, {
  Completer<Map<String, PublicProfile>>? pending,
}) => ProviderScope(
  overrides: [
    productionModeProvider.overrideWithValue(true),
    currentUserIdProvider.overrideWithValue(const AsyncData('me')),
    connectionsProvider.overrideWith((ref) async => _connections),
    chatConversationsProvider.overrideWith((ref) async => _conversations),
    chatMessagesProvider.overrideWith(
      (ref, id) async => [
        Message(
          id: 'message',
          conversationId: id,
          senderUserId: 'a',
          text: 'Hello from the event',
          sentAt: _now,
        ),
      ],
    ),
    chatLatestMessageProvider.overrideWith(
      (ref, id) async => Message(
        id: 'latest',
        conversationId: id,
        senderUserId: 'a',
        text: 'Hello from the event',
        sentAt: _now,
      ),
    ),
    conversationContextProvider.overrideWith((ref, id) async => null),
    notificationsProvider.overrideWith((ref) async => []),
    publicPeerProfilesProvider.overrideWith(
      (ref, ids) => pending?.future ?? Future.value(_profiles),
    ),
  ],
  child: MaterialApp(home: screen),
);

void main() {
  test('stable peer key deduplicates and sorts', () {
    expect(publicPeerIdsKey(['b', 'a', '', 'a']), 'a,b');
  });

  test('profile labels do not invent identity on denied or failed lookup', () {
    expect(peerProfileLabel(const AsyncData({}), 'a'), 'Name unavailable');
    expect(
      peerProfileLabel(AsyncError(StateError('denied'), StackTrace.empty), 'a'),
      'Name unavailable',
    );
    expect(peerProfileLabel(const AsyncLoading(), 'a'), 'Loading name…');
  });

  test(
    'production lookup uses public projection and excludes blocked IDs',
    () async {
      final repository = _Profiles();
      final container = ProviderContainer(
        overrides: [
          productionModeProvider.overrideWithValue(true),
          currentUserIdProvider.overrideWithValue(const AsyncData('me')),
          blockedUsersProvider.overrideWith((ref) async => ['b']),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = publicPeerProfilesProvider('a,b');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final result = await container.read(provider.future);
      expect(repository.requested, {'a'});
      expect(result.keys, ['a']);
      expect(repository.privateReads, 0);
    },
  );

  test(
    'preview provider uses bounded capability, not full message history',
    () async {
      final repository = _PreviewRepository();
      final container = ProviderContainer(
        overrides: [
          productionModeProvider.overrideWithValue(true),
          currentUserIdProvider.overrideWithValue(const AsyncData('me')),
          connectionsProvider.overrideWith((ref) async => _connections),
          chatConversationsProvider.overrideWith((ref) async => _conversations),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = chatLatestMessageProvider('chat-a');
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final latest = await container.read(provider.future);
      expect(latest?.text, 'Bounded latest message');
      expect(repository.previewReads, 1);
      expect(repository.fullReads, 0);
    },
  );

  testWidgets('two real-mode conversations show distinct authorized names', (
    tester,
  ) async {
    await tester.pumpWidget(_fixture(const ChatScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Daniel'), findsOneWidget);
    expect(find.text('Hello from the event'), findsNWidgets(2));
    expect(find.text('Connection'), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('conversation exposes author date time and text semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _fixture(const ConversationScreen(conversationId: 'chat-a')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sofia'), findsNWidgets(2));
    expect(find.text('Conversation'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'Sofia, .+\. Hello from the event')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('name failure is explicit and does not fabricate a name', (
    tester,
  ) async {
    final pending = Completer<Map<String, PublicProfile>>();
    await tester.pumpWidget(_fixture(const ChatScreen(), pending: pending));
    await tester.pump();
    await tester.pump();
    expect(find.text('Loading name…'), findsNWidgets(2));
    pending.completeError(StateError('fixture denied'));
    await tester.pumpAndSettle();
    expect(find.text('Name unavailable'), findsNWidgets(2));
    expect(find.text('Sofia'), findsNothing);
  });
}

class _Profiles implements ProfileRepository, PublicProfileRepository {
  Set<String>? requested;
  int privateReads = 0;
  @override
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(
    Set<String> ids,
  ) async {
    requested = Set.of(ids);
    return {
      for (final id in ids)
        if (_profiles.containsKey(id)) id: _profiles[id]!,
    };
  }

  @override
  Future<PublicProfile?> getPublicProfile(String userId) async =>
      _profiles[userId];
  @override
  Future<UserProfile?> getProfile(String identityId) async {
    privateReads++;
    throw StateError('private data must not be read');
  }

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) => throw UnimplementedError();
  @override
  Future<UserProfile> saveProfile(UserProfile profile) =>
      throw UnimplementedError();
}

class _PreviewRepository
    implements ChatRepository, LatestChatMessageRepository {
  int previewReads = 0;
  int fullReads = 0;
  @override
  Future<Message?> getLatestMessage({
    required String conversationId,
    required String userId,
  }) async {
    previewReads++;
    return Message(
      id: 'last',
      conversationId: conversationId,
      senderUserId: 'a',
      text: 'Bounded latest message',
      sentAt: _now,
    );
  }

  @override
  Future<List<Message>> getMessages({
    required String conversationId,
    required String userId,
  }) async {
    fullReads++;
    return [];
  }

  @override
  Future<List<Conversation>> getConversations(String userId) async =>
      _conversations;
  @override
  Future<Conversation> getOrCreateConversation({
    required String connectionId,
    required String userId,
  }) => throw UnimplementedError();
  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String text,
    String? clientMessageId,
  }) => throw UnimplementedError();
}
