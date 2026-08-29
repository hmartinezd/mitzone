import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/chat/data/local_chat_repository.dart';
import 'package:mitzone/features/chat/presentation/conversation_screen.dart';
import 'package:mitzone/features/connections/data/local_connection_repository.dart';

void main() {
  testWidgets(
    'direct unauthorized conversation route does not expose messages',
    (tester) async {
      final storage = _MemoryStorage();
      final connections = LocalConnectionRepository(storage);
      final chat = LocalChatRepository(storage, connections);
      final request = await connections.sendRequest(
        senderUserId: MockUsers.joseId,
        recipientUserId: MockUsers.sofiaId,
        encounterId: 'encounter',
      );
      await connections.acceptRequest(
        requestId: request.id,
        recipientUserId: MockUsers.sofiaId,
      );
      final connection = (await connections.getConnections(
        MockUsers.joseId,
      )).single;
      final conversation = await chat.getOrCreateConversation(
        connectionId: connection.id,
        userId: MockUsers.joseId,
      );
      await chat.sendMessage(
        conversationId: conversation.id,
        senderUserId: MockUsers.joseId,
        text: 'private message content',
      );
      final router = GoRouter(
        initialLocation: '/app/chat/${conversation.id}',
        routes: [
          GoRoute(
            path: '/app/chat/:conversationId',
            builder: (context, state) => ConversationScreen(
              conversationId: state.pathParameters['conversationId']!,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(chat),
            mockIdentityRepositoryProvider.overrideWith(
              (ref) => InMemoryMockIdentityRepository(
                initialUserId: MockUsers.danielId,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This conversation is unavailable right now.'),
        findsOneWidget,
      );
      expect(find.text('private message content'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.send), findsNothing);
    },
  );
}

class _MemoryStorage implements LocalStorage {
  final values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
