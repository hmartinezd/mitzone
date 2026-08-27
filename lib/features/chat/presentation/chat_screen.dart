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
    return Scaffold(appBar: AppBar(title: const Text('Chat')), body: state.when(loading:()=>const Center(child:CircularProgressIndicator()), error:(e,_)=>Center(child:Text('$e')), data:(items)=>connected.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(e,_)=>Center(child:Text('$e')),data:(connections)=>connections.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(32),child:Text('Your conversations will appear here after you connect with someone you crossed paths with.',textAlign:TextAlign.center))):ListView(children:connections.map((connection){final c=items.where((x)=>x.connectionId==connection.id).firstOrNull;final other=ref.read(mockIdentityRepositoryProvider).users.firstWhere((u)=>u.id==(connection.userAId==current?connection.userBId:connection.userAId));return ListTile(leading:ProfileAvatar(displayName:other.displayName,radius:24),title:Text(other.displayName),subtitle:Text(c==null?'Start a conversation':'Continue your conversation'),onTap:()async{final conversation=c??await ref.read(chatRepositoryProvider).getOrCreateConversation(connectionId:connection.id,userId:current);ref.invalidate(chatConversationsProvider);if(context.mounted)context.push('/app/chat/${conversation.id}');});}).toList()))));
  }
}
