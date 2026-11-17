import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../connections/data/connection_providers.dart';
import '../../chat/data/chat_providers.dart';

/// Shared chrome for the new functional destinations; no presence activation.
class FeatureDestinationHeader extends ConsumerWidget {
  const FeatureDestinationHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Messages',
                onPressed: () {
                  ref.invalidate(connectionsProvider);
                  ref.invalidate(chatConversationsProvider);
                  context.push(AppRoutes.chat);
                },
                icon: const Icon(Icons.chat_bubble_outline),
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    ),
  );
}
