import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/core_providers.dart';

class FoundationScreen extends ConsumerWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              theme.colorScheme.tertiary.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48),
                            Icon(
                              Icons.location_on_outlined,
                              size: 80,
                              color: theme.colorScheme.primary,
                              semanticLabel: 'Mitzone location logo',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mitzone',
                              style: theme.textTheme.displayLarge,
                              semanticsLabel: 'Product name: Mitzone',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'The best connections begin in the real world.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              'Foundation Ready (Android & iOS)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _InfoTile(
                              label: 'Environment',
                              value: config.env.name.toUpperCase(),
                              icon: Icons.settings_suggest_outlined,
                            ),
                            _InfoTile(
                              label: 'Supabase Status',
                              value: config.isSupabaseConfigured
                                  ? 'Configured'
                                  : 'Not Configured',
                              valueColor: config.isSupabaseConfigured
                                  ? AppColors.success
                                  : AppColors.warning,
                              icon: config.isSupabaseConfigured
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_off_outlined,
                            ),
                            const SizedBox(height: 48),
                            Text(
                              'Product features and authentication are not part of this phase.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
