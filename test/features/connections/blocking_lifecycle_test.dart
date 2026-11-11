import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/blocking/data/local_block_repository.dart';
import 'package:mitzone/features/connections/data/local_connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection_request.dart';
import 'package:mitzone/features/chat/data/local_chat_repository.dart';
import '../../support/memory_local_storage.dart';

void main() {
  for (final blocker in ['a', 'b']) {
    test(
      'block by $blocker terminates consent and history access across unblock and reconnect',
      () async {
        final storage = MemoryLocalStorage();
        final blocks = LocalBlockRepository(storage);
        final connections = LocalConnectionRepository(storage, blocks: blocks);
        final chat = LocalChatRepository(storage, connections);
        final request = await connections.sendRequest(
          senderUserId: 'a',
          recipientUserId: 'b',
          encounterId: 'encounter',
        );
        await connections.acceptRequest(
          requestId: request.id,
          recipientUserId: 'b',
        );
        final old = (await connections.getConnections('a')).single;
        final conversation = await chat.getOrCreateConversation(
          connectionId: old.id,
          userId: 'a',
        );
        await chat.sendMessage(
          conversationId: conversation.id,
          senderUserId: 'a',
          text: 'retained private history',
        );
        final history = await storage.getString(LocalChatRepository.key);
        final other = blocker == 'a' ? 'b' : 'a';
        await blocks.block(blockerUserId: blocker, blockedUserId: other);

        Future<void> assertHistoryInaccessible() async {
          for (final user in ['a', 'b']) {
            expect(await connections.getConnections(user), isEmpty);
            expect(await chat.getConversations(user), isEmpty);
            expect(await connections.getOutgoingRequests(user), isEmpty);
            await expectLater(
              chat.getMessages(conversationId: conversation.id, userId: user),
              throwsStateError,
            );
            await expectLater(
              chat.sendMessage(
                conversationId: conversation.id,
                senderUserId: user,
                text: 'disallowed',
              ),
              throwsStateError,
            );
            await expectLater(
              chat.getOrCreateConversation(connectionId: old.id, userId: user),
              throwsStateError,
            );
          }
          expect(await storage.getString(LocalChatRepository.key), history);
        }

        await assertHistoryInaccessible();
        for (final user in ['a', 'b']) {
          await expectLater(
            connections.sendRequest(
              senderUserId: user,
              recipientUserId: user == 'a' ? 'b' : 'a',
              encounterId: 'encounter',
            ),
            throwsStateError,
          );
        }
        await blocks.unblock(blockerUserId: blocker, blockedUserId: other);
        await assertHistoryInaccessible();
        await expectLater(
          connections.acceptRequest(
            requestId: request.id,
            recipientUserId: 'b',
          ),
          throwsStateError,
        );
        final fresh = await connections.sendRequest(
          senderUserId: 'a',
          recipientUserId: 'b',
          encounterId: 'encounter',
        );
        expect(fresh.id, isNot(request.id));
        expect(fresh.status, ConnectionRequestStatus.pending);
        expect(await connections.getConnections('a'), isEmpty);
        await connections.acceptRequest(
          requestId: fresh.id,
          recipientUserId: 'b',
        );
        final current = (await connections.getConnections('a')).single;
        expect(current.id, isNot(old.id));
        final freshChat = await chat.getOrCreateConversation(
          connectionId: current.id,
          userId: 'a',
        );
        expect(freshChat.id, isNot(conversation.id));
        expect(
          await chat.getMessages(conversationId: freshChat.id, userId: 'b'),
          isEmpty,
        );
        for (final user in ['a', 'b']) {
          await expectLater(
            chat.getMessages(conversationId: conversation.id, userId: user),
            throwsStateError,
          );
          await expectLater(
            chat.sendMessage(
              conversationId: conversation.id,
              senderUserId: user,
              text: 'disallowed',
            ),
            throwsStateError,
          );
        }
        final persisted =
            jsonDecode((await storage.getString(LocalChatRepository.key))!)
                as Map;
        expect(
          (persisted['messages'] as List).single['text'],
          'retained private history',
        );
      },
    );
  }

  test(
    'a request pending before a block cannot be accepted after unblock',
    () async {
      final storage = MemoryLocalStorage();
      final blocks = LocalBlockRepository(storage);
      final connections = LocalConnectionRepository(storage, blocks: blocks);
      final request = await connections.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter',
      );
      await blocks.block(blockerUserId: 'b', blockedUserId: 'a');
      await expectLater(
        connections.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        throwsStateError,
      );
      await blocks.unblock(blockerUserId: 'b', blockedUserId: 'a');
      await expectLater(
        connections.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        throwsStateError,
      );
      expect(await connections.getConnections('a'), isEmpty);
    },
  );

  test(
    'concurrent acceptance and blocking cannot leave an active relationship',
    () async {
      final storage = MemoryLocalStorage();
      final blocks = LocalBlockRepository(storage);
      final connections = LocalConnectionRepository(storage, blocks: blocks);
      final request = await connections.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter',
      );
      await Future.wait([
        connections.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        blocks.block(blockerUserId: 'a', blockedUserId: 'b'),
      ]);
      await blocks.unblock(blockerUserId: 'a', blockedUserId: 'b');
      expect(await connections.getConnections('a'), isEmpty);
      await expectLater(
        connections.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        throwsStateError,
      );
    },
  );
  test('unblock without an existing block does not end a connection', () async {
    final storage = MemoryLocalStorage();
    final blocks = LocalBlockRepository(storage);
    final connections = LocalConnectionRepository(storage, blocks: blocks);
    final request = await connections.sendRequest(
      senderUserId: 'a',
      recipientUserId: 'b',
      encounterId: 'encounter',
    );
    await connections.acceptRequest(
      requestId: request.id,
      recipientUserId: 'b',
    );
    await blocks.unblock(blockerUserId: 'a', blockedUserId: 'b');
    expect(await connections.getConnections('a'), hasLength(1));
  });

  test(
    'legacy hidden relationships are invalidated before lifting a block',
    () async {
      final storage = MemoryLocalStorage();
      final blocks = LocalBlockRepository(storage);
      final connections = LocalConnectionRepository(storage, blocks: blocks);
      final request = await connections.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter',
      );
      await connections.acceptRequest(
        requestId: request.id,
        recipientUserId: 'b',
      );
      // Reproduce storage from the old implementation, which only wrote a block.
      await storage.setString(blocks.key('a'), jsonEncode(['b']));
      await blocks.unblock(blockerUserId: 'a', blockedUserId: 'b');
      expect(await connections.getConnections('a'), isEmpty);
      await expectLater(
        connections.acceptRequest(requestId: request.id, recipientUserId: 'b'),
        throwsStateError,
      );
    },
  );

  test('unreadable block state cannot authorize connections or chat', () async {
    final storage = MemoryLocalStorage();
    final blocks = LocalBlockRepository(storage);
    final connections = LocalConnectionRepository(storage, blocks: blocks);
    final request = await connections.sendRequest(
      senderUserId: 'a',
      recipientUserId: 'b',
      encounterId: 'encounter',
    );
    await connections.acceptRequest(
      requestId: request.id,
      recipientUserId: 'b',
    );
    final chat = LocalChatRepository(storage, connections);
    final conversation = await chat.getOrCreateConversation(
      connectionId: (await connections.getConnections('a')).single.id,
      userId: 'a',
    );
    await storage.setString(blocks.key('a'), '{invalid');
    await expectLater(connections.getConnections('a'), throwsFormatException);
    await expectLater(
      chat.getMessages(conversationId: conversation.id, userId: 'a'),
      throwsFormatException,
    );
    await expectLater(
      connections.sendRequest(
        senderUserId: 'a',
        recipientUserId: 'b',
        encounterId: 'encounter',
      ),
      throwsFormatException,
    );
  });
}
