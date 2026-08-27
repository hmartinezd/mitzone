import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../../connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this.storage, this.connections, {DateTime Function()? now}) : now = now ?? (() => DateTime.now().toUtc());
  final LocalStorage storage; final ConnectionRepository connections; final DateTime Function() now;
  static const key = 'local_chat.v1';
  Future<Map<String,dynamic>> _read() async { try { final d=jsonDecode(await storage.getString(key) ?? '{}'); return d is Map ? {'conversations': d['conversations'] is List ? d['conversations'] : [], 'messages': d['messages'] is List ? d['messages'] : []} : {'conversations': [], 'messages': []}; } catch (_) { return {'conversations': [], 'messages': []}; } }
  Future<void> _write(Map<String,dynamic> d) => storage.setString(key, jsonEncode(d));
  Conversation? _conversation(Object? x) { try { if(x is! Map) return null; final id=x['id'], c=x['connectionId'], a=x['a'], b=x['b'], t=DateTime.tryParse(x['createdAt']??''); if([id,c,a,b].any((v)=>v is! String)||t==null) return null; return Conversation(id:id,connectionId:c,userAId:a,userBId:b,createdAt:t,lastMessageAt:DateTime.tryParse(x['lastMessageAt']??'')); } catch(_){return null;} }
  Message? _message(Object? x) { try { if(x is! Map) return null; final t=DateTime.tryParse(x['sentAt']??''); if([x['id'],x['conversationId'],x['sender'],x['text']].any((v)=>v is! String)||t==null) return null; return Message(id:x['id'],conversationId:x['conversationId'],senderUserId:x['sender'],text:x['text'],sentAt:t); } catch(_){return null;} }
  Map<String,dynamic> _cj(Conversation c)=>{'id':c.id,'connectionId':c.connectionId,'a':c.userAId,'b':c.userBId,'createdAt':c.createdAt.toIso8601String(),if(c.lastMessageAt!=null)'lastMessageAt':c.lastMessageAt!.toIso8601String()};
  Map<String,dynamic> _mj(Message m)=>{'id':m.id,'conversationId':m.conversationId,'sender':m.senderUserId,'text':m.text,'sentAt':m.sentAt.toIso8601String()};
  @override Future<List<Conversation>> getConversations(String userId) async => (await _read())['conversations'].map(_conversation).whereType<Conversation>().where((c)=>c.userAId==userId||c.userBId==userId).toList();
  Future<Connection> _authorized(String id,String user) async { final cs=await connections.getConnections(user); final c=cs.where((x)=>x.id==id).firstOrNull; if(c==null) throw StateError('Chat requires an active connection'); return c; }
  @override Future<Conversation> getOrCreateConversation({required String connectionId,required String userId}) async { final c=await _authorized(connectionId,userId); final d=await _read(); final list=d['conversations'].map(_conversation).whereType<Conversation>().toList(); final found=list.where((x)=>x.connectionId==c.id).firstOrNull; if(found!=null)return found; final x=Conversation(id:'conversation_${c.id}',connectionId:c.id,userAId:c.userAId,userBId:c.userBId,createdAt:now().toUtc()); list.add(x); d['conversations']=list.map(_cj).toList(); await _write(d); return x; }
  @override Future<List<Message>> getMessages(String id) async => (await _read())['messages'].map(_message).whereType<Message>().where((m)=>m.conversationId==id).toList()..sort((a,b)=>a.sentAt.compareTo(b.sentAt));
  @override Future<Message> sendMessage({required String conversationId,required String senderUserId,required String text}) async { final value=text.trim(); if(value.isEmpty)throw ArgumentError('Message cannot be empty'); final d=await _read(); final cs=d['conversations'].map(_conversation).whereType<Conversation>().toList(); final c=cs.where((x)=>x.id==conversationId).firstOrNull; if(c==null|| (c.userAId!=senderUserId&&c.userBId!=senderUserId))throw StateError('Sender is not in conversation'); await _authorized(c.connectionId,senderUserId); final m=Message(id:'message_${now().microsecondsSinceEpoch}',conversationId:conversationId,senderUserId:senderUserId,text:value,sentAt:now().toUtc()); d['messages']=[...d['messages'],_mj(m)]; await _write(d); return m; }
}
