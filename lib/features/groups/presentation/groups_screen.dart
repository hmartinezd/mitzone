import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../navigation/presentation/feature_destination_header.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const FeatureDestinationHeader(
          title: 'Groups',
          subtitle: 'Group features are not implemented in this beta.',
        ),
        Expanded(
          child: SingleChildScrollView(
            child: MitzoneEmptyState(
              title: 'Groups are not available yet',
              message:
                  'There are no group creation or membership tools in this beta. You can still discover activities and connect through shared moments.',
              icon: Icons.groups_outlined,
              primaryAction: FilledButton(
                onPressed: () => context.go(AppRoutes.explore),
                child: const Text('Explore activities'),
              ),
              secondaryAction: TextButton(
                onPressed: () => context.go(AppRoutes.nearby),
                child: const Text('Find shared moments'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
