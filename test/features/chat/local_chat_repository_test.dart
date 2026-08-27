import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/chat/data/local_chat_repository.dart';
import 'package:mitzone/features/connections/data/local_connection_repository.dart';

void main() {
  late MemoryStorage storage;
  late LocalConnectionRepository connections;
  late LocalChatRepository chat;
  var tick = 0;

  setUp(() async {
    storage = MemoryStorage();
    connections = LocalConnectionRepository(
      storage,
      now: () => DateTime.utc(2026, 8, 27),
    );
    chat = LocalChatRepository(
      storage,
      connections,
      now: () => DateTime.utc(2026, 8, 27, 12, tick++),
    );
  });

  Future<String> connect(String a, String b) async {
    final request = await connections.sendRequest(
      senderUserId: a,
      recipientUserId: b,
      encounterId: 'encounter-$a-$b',
    );
    await connections.acceptRequest(requestId: request.id, recipientUserId: b);
    return (await connections.getConnections(a))
        .singleWhere(
          (connection) => connection.userAId == b || connection.userBId == b,
        )
        .id;
  }

  test('conversation requires an active connection', () async {
    await expectLater(
      chat.getOrCreateConversation(connectionId: 'missing', userId: 'a'),
      throwsStateError,
    );
  });

  test('creates exactly one usable conversation per connection', () async {
    final connectionId = await connect('a', 'b');
    final first = await chat.getOrCreateConversation(
      connectionId: connectionId,
      userId: 'a',
    );
    final second = await chat.getOrCreateConversation(
      connectionId: connectionId,
      userId: 'b',
    );
    expect(second.id, first.id);
    expect(await chat.getConversations('a'), hasLength(1));
    expect(await chat.getMessages(first.id), isEmpty);
  });

  test(
    'participants send trimmed UTC messages that persist chronologically',
    () async {
      final connectionId = await connect('a', 'b');
      final conversation = await chat.getOrCreateConversation(
        connectionId: connectionId,
        userId: 'a',
      );
      final first = await chat.sendMessage(
        conversationId: conversation.id,
        senderUserId: 'a',
        text: '  hello  ',
      );
      final second = await chat.sendMessage(
        conversationId: conversation.id,
        senderUserId: 'b',
        text: 'hi',
      );
      expect(first.text, 'hello');
      expect(first.sentAt.isUtc, isTrue);
      final reloaded = LocalChatRepository(storage, connections);
      expect((await reloaded.getMessages(conversation.id)).map((m) => m.id), [
        first.id,
        second.id,
      ]);
      expect(
        (await reloaded.getConversations('a')).single.lastMessageAt,
        second.sentAt,
      );
    },
  );

  test(
    'rejects empty messages, outsiders, and disconnected participants',
    () async {
      final connectionId = await connect('a', 'b');
      final conversation = await chat.getOrCreateConversation(
        connectionId: connectionId,
        userId: 'a',
      );
      await expectLater(
        chat.sendMessage(
          conversationId: conversation.id,
          senderUserId: 'a',
          text: '   ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        chat.sendMessage(
          conversationId: conversation.id,
          senderUserId: 'outsider',
          text: 'hello',
        ),
        throwsStateError,
      );
      await storage.setString(
        LocalConnectionRepository.key,
        jsonEncode({'requests': [], 'connections': []}),
      );
      await expectLater(
        chat.sendMessage(
          conversationId: conversation.id,
          senderUserId: 'a',
          text: 'hello',
        ),
        throwsStateError,
      );
    },
  );

  test('orders conversations by latest activity', () async {
    final firstConnection = await connect('a', 'b');
    final secondConnection = await connect('a', 'c');
    final first = await chat.getOrCreateConversation(
      connectionId: firstConnection,
      userId: 'a',
    );
    final second = await chat.getOrCreateConversation(
      connectionId: secondConnection,
      userId: 'a',
    );
    await chat.sendMessage(
      conversationId: first.id,
      senderUserId: 'a',
      text: 'latest',
    );
    expect((await chat.getConversations('a')).map((c) => c.id), [
      first.id,
      second.id,
    ]);
  });

  test('malformed persisted chat state fails safely', () async {
    await storage.setString(LocalChatRepository.key, '{not json');
    expect(await chat.getConversations('a'), isEmpty);
    expect(await chat.getMessages('conversation'), isEmpty);

    await storage.setString(
      LocalChatRepository.key,
      jsonEncode({
        'conversations': [
          42,
          {'id': 'broken'},
        ],
        'messages': [
          'bad',
          {'sentAt': 'not-a-date'},
        ],
      }),
    );
    expect(await chat.getConversations('a'), isEmpty);
    expect(await chat.getMessages('conversation'), isEmpty);
  });
}

class MemoryStorage implements LocalStorage {
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
