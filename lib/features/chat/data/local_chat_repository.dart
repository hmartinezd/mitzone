import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../../connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import '../../notifications/domain/notification_repository.dart';
import '../../notifications/domain/local_notification.dart';

class LocalChatRepository implements ChatRepository {
  LocalChatRepository(
    this.storage,
    this.connections, {
    DateTime Function()? now,
    this.notifications,
  }) : now = now ?? (() => DateTime.now().toUtc());
  final LocalStorage storage;
  final ConnectionRepository connections;
  final DateTime Function() now;
  final NotificationRepository? notifications;
  static const key = 'local_chat.v1';
  Future<Map<String, dynamic>> _read() async {
    try {
      final d = jsonDecode(await storage.getString(key) ?? '{}');
      return d is Map
          ? {
              'conversations': d['conversations'] is List
                  ? d['conversations']
                  : [],
              'messages': d['messages'] is List ? d['messages'] : [],
            }
          : {'conversations': [], 'messages': []};
    } catch (_) {
      return {'conversations': [], 'messages': []};
    }
  }

  Future<void> _write(Map<String, dynamic> d) =>
      storage.setString(key, jsonEncode(d));
  Conversation? _conversation(Object? x) {
    try {
      if (x is! Map) return null;
      final id = x['id'],
          c = x['connectionId'],
          a = x['a'],
          b = x['b'],
          t = DateTime.tryParse(x['createdAt'] ?? '');
      if ([id, c, a, b].any((v) => v is! String) || t == null) return null;
      return Conversation(
        id: id,
        connectionId: c,
        userAId: a,
        userBId: b,
        createdAt: t,
        lastMessageAt: DateTime.tryParse(x['lastMessageAt'] ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Message? _message(Object? x) {
    try {
      if (x is! Map) return null;
      final t = DateTime.tryParse(x['sentAt'] ?? '');
      if ([
            x['id'],
            x['conversationId'],
            x['sender'],
            x['text'],
          ].any((v) => v is! String) ||
          t == null) {
        return null;
      }
      return Message(
        id: x['id'],
        conversationId: x['conversationId'],
        senderUserId: x['sender'],
        text: x['text'],
        sentAt: t,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _cj(Conversation c) => {
    'id': c.id,
    'connectionId': c.connectionId,
    'a': c.userAId,
    'b': c.userBId,
    'createdAt': c.createdAt.toIso8601String(),
    if (c.lastMessageAt != null)
      'lastMessageAt': c.lastMessageAt!.toIso8601String(),
  };
  Map<String, dynamic> _mj(Message m) => {
    'id': m.id,
    'conversationId': m.conversationId,
    'sender': m.senderUserId,
    'text': m.text,
    'sentAt': m.sentAt.toIso8601String(),
  };

  List<Conversation> _conversations(Object? raw) => raw is List
      ? raw.map(_conversation).whereType<Conversation>().toList()
      : <Conversation>[];

  List<Message> _messages(Object? raw) => raw is List
      ? raw.map(_message).whereType<Message>().toList()
      : <Message>[];

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    final all = _conversations(
      (await _read())['conversations'],
    ).where((c) => c.userAId == userId || c.userBId == userId).toList();
    final active = await connections.getConnections(userId);
    final activeIds = active.map((c) => c.id).toSet();
    final conversations = all
        .where((c) => activeIds.contains(c.connectionId))
        .toList();
    conversations.sort((a, b) {
      final aActivity = a.lastMessageAt ?? a.createdAt;
      final bActivity = b.lastMessageAt ?? b.createdAt;
      return bActivity.compareTo(aActivity);
    });
    return conversations;
  }

  Future<Connection> _authorized(String id, String user) async {
    final cs = await connections.getConnections(user);
    final c = cs.where((x) => x.id == id).firstOrNull;
    if (c == null) throw StateError('Chat requires an active connection');
    return c;
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String connectionId,
    required String userId,
  }) async {
    final c = await _authorized(connectionId, userId);
    final d = await _read();
    final list = _conversations(d['conversations']);
    final found = list.where((x) => x.connectionId == c.id).firstOrNull;
    if (found != null) return found;
    final x = Conversation(
      id: 'conversation_${c.id}',
      connectionId: c.id,
      userAId: c.userAId,
      userBId: c.userBId,
      createdAt: now().toUtc(),
    );
    list.add(x);
    d['conversations'] = list.map(_cj).toList();
    await _write(d);
    return x;
  }

  @override
  Future<List<Message>> getMessages({
    required String conversationId,
    required String userId,
  }) async {
    final data = await _read();
    final conversation = _conversations(
      data['conversations'],
    ).where((item) => item.id == conversationId).firstOrNull;
    if (conversation == null) throw StateError('Conversation was not found');
    if (conversation.userAId != userId && conversation.userBId != userId) {
      throw StateError('User is not in conversation');
    }
    await _authorized(conversation.connectionId, userId);
    return _messages(
        data['messages'],
      ).where((message) => message.conversationId == conversationId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String text,
    String? clientMessageId,
  }) async {
    final value = text.trim();
    if (value.isEmpty) throw ArgumentError('Message cannot be empty');
    final d = await _read();
    final cs = _conversations(d['conversations']);
    final index = cs.indexWhere((x) => x.id == conversationId);
    if (index < 0) throw StateError('Conversation was not found');
    final c = cs[index];
    if (c.userAId != senderUserId && c.userBId != senderUserId) {
      throw StateError('Sender is not in conversation');
    }
    await _authorized(c.connectionId, senderUserId);
    final timestamp = now().toUtc();
    final m = Message(
      id: 'message_${clientMessageId ?? timestamp.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderUserId: senderUserId,
      text: value,
      sentAt: timestamp,
    );
    cs[index] = Conversation(
      id: c.id,
      connectionId: c.connectionId,
      userAId: c.userAId,
      userBId: c.userBId,
      createdAt: c.createdAt,
      lastMessageAt: timestamp,
    );
    d['conversations'] = cs.map(_cj).toList();
    d['messages'] = [..._messages(d['messages']).map(_mj), _mj(m)];
    await _write(d);
    final other = c.userAId == senderUserId ? c.userBId : c.userAId;
    await notifications?.add(
      LocalNotification(
        id: 'message_${m.id}',
        type: LocalNotificationType.newMessage,
        userId: other,
        timestamp: timestamp,
        entityId: conversationId,
        destination: '/app/chat/$conversationId',
      ),
    );
    return m;
  }
}
