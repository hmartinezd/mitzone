import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';

/// Screen displayed when application entry resolution fails.
class EntryFailureScreen extends StatelessWidget {
  const EntryFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageScaffold(
      showAppBar: false,
      child: MitzoneEmptyState(
        title: "Could not continue",
        message: "We couldn't load Mitzone on this device. Please try again.",
        icon: Icons.error_outline,
        primaryAction: MitzoneButton(
          text: 'Try again',
          onPressed: () => context.go(AppRoutes.splash),
        ),
      ),
    );
  }
}
