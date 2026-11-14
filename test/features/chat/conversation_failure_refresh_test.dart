import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/chat/domain/chat_models.dart';
import 'package:mitzone/features/chat/domain/chat_repository.dart';
import 'package:mitzone/features/chat/presentation/conversation_screen.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';

Widget _fixture(_Chat chat) => ProviderScope(
  overrides: [
    productionModeProvider.overrideWithValue(true),
    currentUserIdProvider.overrideWithValue(const AsyncData('fixture-user')),
    connectionsProvider.overrideWith((ref) async => []),
    chatRepositoryProvider.overrideWithValue(chat),
    conversationContextProvider.overrideWith((ref, id) async => null),
  ],
  child: const MaterialApp(
    home: ConversationScreen(conversationId: 'fixture-conversation'),
  ),
);

void main() {
  testWidgets(
    'send is guarded, failure preserves draft and retry identity; edits receive a new identity',
    (tester) async {
      final chat = _Chat();
      await tester.pumpWidget(_fixture(chat));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'first draft');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(chat.sent.length, 1);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      chat.pending!.completeError(StateError('fixture unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('first draft'), findsOneWidget);
      final firstId = chat.sent.single.$2;
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(chat.sent.last.$2, firstId);
      chat.pending!.completeError(StateError('fixture unavailable'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'changed draft');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(chat.sent.last.$2, isNot(firstId));
      expect(chat.sent.last.$1, 'changed draft');
      chat.pending!.complete(chat.message('changed draft'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'foreground refresh receives messages, pauses in background and closes revoked access',
    (tester) async {
      final chat = _Chat();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(_fixture(chat));
      await tester.pumpAndSettle();
      chat.messages.add(chat.message('incoming fixture'));
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('incoming fixture'), findsOneWidget);
      final reads = chat.reads;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(chat.reads, reads);
      chat.denied = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('incoming fixture'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('This conversation is unavailable right now.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Chat implements ChatRepository {
  final messages = <Message>[];
  final sent = <(String, String?)>[];
  Completer<Message>? pending;
  int reads = 0;
  bool denied = false;
  Message message(String text) => Message(
    id: 'fixture-message',
    conversationId: 'fixture-conversation',
    senderUserId: 'fixture-peer',
    text: text,
    sentAt: DateTime.utc(2026),
  );
  @override
  Future<List<Conversation>> getConversations(String userId) async => [];
  @override
  Future<Conversation> getOrCreateConversation({
    required String connectionId,
    required String userId,
  }) => throw UnimplementedError();
  @override
  Future<List<Message>> getMessages({
    required String conversationId,
    required String userId,
  }) async {
    reads++;
    if (denied) throw StateError('fixture revoked');
    return List.of(messages);
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String text,
    String? clientMessageId,
  }) {
    sent.add((text, clientMessageId));
    pending = Completer<Message>();
    return pending!.future;
  }
}
