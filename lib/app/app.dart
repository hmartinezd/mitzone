import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/notifications/data/push_lifecycle_provider.dart';
import '../core/observability/observability.dart';
import '../core/observability/observability_provider.dart';

class MitzoneApp extends ConsumerStatefulWidget {
  const MitzoneApp({super.key});

  @override
  ConsumerState<MitzoneApp> createState() => _MitzoneAppState();
}

class _MitzoneAppState extends ConsumerState<MitzoneApp> {
  bool _loggedOpen = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushLifecycleProvider);
    if (!_loggedOpen) {
      _loggedOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(observabilityProvider).log(MitzoneEvents.appOpened);
      });
    }
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mitzone',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
