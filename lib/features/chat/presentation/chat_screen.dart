import 'package:flutter/material.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MitzonePageBody(
      title: 'Chat',
      child: MitzoneEmptyState(
        title: 'No conversations yet',
        message: 'Start a conversation with your matches to see them here.',
        icon: Icons.chat_bubble_outline,
      ),
    );
  }
}
