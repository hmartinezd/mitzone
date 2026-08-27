import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../../../features/profile/presentation/widgets/profile_avatar.dart';
import '../data/chat_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../domain/chat_models.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state=ref.watch(chatConversationsProvider); final connected=ref.watch(connectionsProvider); final current=ref.watch(mockIdentityRepositoryProvider).currentUser.id;
    return Scaffold(appBar: AppBar(title: const Text('Chat')), body: state.when(loading:()=>const Center(child:CircularProgressIndicator()), error:(_,__)=>const Center(child:Text('Your conversations are unavailable right now.')), data:(items)=>connected.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(_,__)=>const Center(child:Text('Your connections are unavailable right now.')),data:(connections){final ordered=[...connections]..sort((a,b){final ac=items.where((x)=>x.connectionId==a.id).firstOrNull,bc=items.where((x)=>x.connectionId==b.id).firstOrNull;final at=ac?.lastMessageAt,bt=bc?.lastMessageAt;if(at==null&&bt==null)return a.id.compareTo(b.id);if(at==null)return 1;if(bt==null)return -1;return bt.compareTo(at);});return ordered.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(32),child:Text('Your conversations will appear here after you connect with someone you crossed paths with.',textAlign:TextAlign.center))):ListView(children:ordered.map((connection){final c=items.where((x)=>x.connectionId==connection.id).firstOrNull;final other=ref.watch(mockIdentityRepositoryProvider).users.firstWhere((u)=>u.id==(connection.userAId==current?connection.userBId:connection.userAId));final latest=ref.watch(chatMessagesProvider(c?.id??''));final preview=latest.valueOrNull?.isNotEmpty==true?latest.value!.last.text:(c==null?'Start a conversation':'Start a conversation');return ListTile(leading:ProfileAvatar(displayName:other.displayName,radius:24),title:Text(other.displayName),subtitle:Text(preview),onTap:()async{try{final conversation=c??await ref.read(chatRepositoryProvider).getOrCreateConversation(connectionId:connection.id,userId:current);ref.invalidate(chatConversationsProvider);if(context.mounted)context.push('/app/chat/${conversation.id}');}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('This conversation is no longer available.')));}});}).toList());}))); 
  }
}
