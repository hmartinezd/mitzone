import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return MitzonePageScaffold(
      title: 'Page Not Found',
      child: MitzoneEmptyState(
        title: 'Lost your way?',
        message: 'The page you are looking for does not exist.',
        icon: Icons.map_outlined,
        primaryAction: MitzoneButton(
          text: 'Return to Mitzone',
          onPressed: () => context.go(AppRoutes.splash),
        ),
      ),
    );
  }
}
