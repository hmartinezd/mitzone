import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  const SupabaseChatRepository(this.client); final SupabaseClient client;
  String _own(String id) { final me=client.auth.currentUser?.id; if(me==null||me!=id) throw StateError('Authentication required'); return me; }
  Conversation _conversation(Map<String,dynamic> r)=>Conversation(id:r['id'] as String,connectionId:r['connection_id'] as String,userAId:r['user_a_id'] as String,userBId:r['user_b_id'] as String,createdAt:DateTime.parse(r['created_at'] as String),lastMessageAt:r['last_message_at']==null?null:DateTime.parse(r['last_message_at'] as String));
  Message _message(Map<String,dynamic> r)=>Message(id:r['id'] as String,conversationId:r['conversation_id'] as String,senderUserId:r['sender_user_id'] as String,text:r['body'] as String,sentAt:DateTime.parse(r['created_at'] as String));
  @override Future<List<Conversation>> getConversations(String userId) async { final me=_own(userId); final rows=await client.from('conversations').select().or('user_a_id.eq.$me,user_b_id.eq.$me').order('last_message_at',ascending:false,nullsFirst:false); return [for(final r in rows)_conversation(r)]; }
  @override Future<Conversation> getOrCreateConversation({required String connectionId,required String userId}) async { _own(userId); return _conversation((await client.rpc('get_or_create_conversation',params:{'p_connection_id':connectionId})) as Map<String,dynamic>); }
  @override Future<List<Message>> getMessages({required String conversationId,required String userId}) async { _own(userId); final rows=await client.rpc('get_conversation_messages',params:{'p_conversation_id':conversationId}); return [for(final r in rows as List)_message(r)]; }
  @override Future<Message> sendMessage({required String conversationId,required String senderUserId,required String text, String? clientMessageId}) async { _own(senderUserId); final value=text.trim(); if(value.isEmpty||value.length>2000) throw ArgumentError('Invalid message'); if(clientMessageId==null||clientMessageId.isEmpty) throw ArgumentError('A stable client message ID is required'); return _message((await client.rpc('send_message',params:{'p_conversation_id':conversationId,'p_body':value,'p_client_message_id':clientMessageId})) as Map<String,dynamic>); }
}
