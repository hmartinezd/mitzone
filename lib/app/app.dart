import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/notifications/data/push_lifecycle_provider.dart';

class MitzoneApp extends ConsumerWidget {
  const MitzoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushLifecycleProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mitzone',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
