import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/widgets/mitzone_brand.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_confirmation_dialog.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';
import '../../../shared/widgets/mitzone_status_badge.dart';
import '../../../shared/widgets/mitzone_text_field.dart';

class VisualSystemShowcaseScreen extends ConsumerStatefulWidget {
  const VisualSystemShowcaseScreen({super.key});

  @override
  ConsumerState<VisualSystemShowcaseScreen> createState() =>
      _VisualSystemShowcaseScreenState();
}

class _VisualSystemShowcaseScreenState
    extends ConsumerState<VisualSystemShowcaseScreen> {
  bool _isButtonLoading = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);

    return MitzonePageScaffold(
      title: 'Visual System Showcase',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Mitzone Brand',
            children: [
              const MitzoneBrand(showTagline: true),
              const SizedBox(height: AppSpacing.lg),
              const Center(child: MitzoneBrand(size: 80, showText: false)),
            ],
          ),
          _Section(
            title: 'Environment Status',
            children: [
              MitzoneCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'Environment', value: config.env.name),
                    const Divider(),
                    _InfoRow(
                      label: 'Supabase Status',
                      value: config.isSupabaseConfigured
                          ? 'Configured'
                          : 'Unconfigured',
                      valueColor: config.isSupabaseConfigured
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Section(
            title: 'Typography',
            children: [
              Text('Display Large', style: theme.textTheme.displayLarge),
              Text('Display Medium', style: theme.textTheme.displayMedium),
              Text('Display Small', style: theme.textTheme.displaySmall),
              const Divider(),
              Text('Headline Large', style: theme.textTheme.headlineLarge),
              Text('Headline Medium', style: theme.textTheme.headlineMedium),
              Text('Headline Small', style: theme.textTheme.headlineSmall),
              const Divider(),
              Text('Title Large', style: theme.textTheme.titleLarge),
              Text('Title Medium', style: theme.textTheme.titleMedium),
              Text('Title Small', style: theme.textTheme.titleSmall),
              const Divider(),
              Text('Body Large', style: theme.textTheme.bodyLarge),
              Text('Body Medium', style: theme.textTheme.bodyMedium),
              Text('Body Small', style: theme.textTheme.bodySmall),
              const Divider(),
              Text('Label Large', style: theme.textTheme.labelLarge),
              Text('Label Medium', style: theme.textTheme.labelMedium),
              Text('Label Small', style: theme.textTheme.labelSmall),
            ],
          ),
          _Section(
            title: 'Buttons',
            children: [
              MitzoneButton(
                text: 'Primary Button',
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Secondary Button',
                variant: MitzoneButtonVariant.secondary,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Tertiary Button',
                variant: MitzoneButtonVariant.tertiary,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Destructive Button',
                variant: MitzoneButtonVariant.destructive,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Loading Button',
                isLoading: _isButtonLoading,
                onPressed: () async {
                  setState(() => _isButtonLoading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _isButtonLoading = false);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneButton(
                text: 'Disabled Button',
                enabled: false,
                onPressed: null,
              ),
            ],
          ),
          _Section(
            title: 'Text Fields',
            children: [
              const MitzoneTextField(
                label: 'Default Text Field',
                hint: 'Enter some text',
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneTextField(
                label: 'Focusable Text Field',
                prefixIcon: Icon(Icons.person_outline),
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneTextField(
                label: 'Error Text Field',
                errorText: 'This is an error message',
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneTextField(
                label: 'Disabled Text Field',
                enabled: false,
                hint: 'Cannot edit this',
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneTextField(
                label: 'Password Field',
                obscureText: true,
                showObscureToggle: true,
              ),
            ],
          ),
          _Section(
            title: 'Cards',
            children: [
              const MitzoneCard(
                child: Text('This is a standard Mitzone card.'),
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneCard(
                onTap: () {},
                leading: const Icon(Icons.touch_app),
                child: const Text('This is a tappable Mitzone card.'),
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneCard(
                selected: true,
                child: Text('This is a selected Mitzone card.'),
              ),
            ],
          ),
          _Section(
            title: 'Status Badges',
            children: [
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  MitzoneStatusBadge(text: 'Neutral', status: MitzoneStatus.neutral),
                  MitzoneStatusBadge(text: 'Info', status: MitzoneStatus.info),
                  MitzoneStatusBadge(text: 'Success', status: MitzoneStatus.success),
                  MitzoneStatusBadge(text: 'Warning', status: MitzoneStatus.warning),
                  MitzoneStatusBadge(text: 'Error', status: MitzoneStatus.error),
                ],
              ),
            ],
          ),
          _Section(
            title: 'Feedback Banners',
            children: [
              const MitzoneFeedbackBanner(
                title: 'Informational',
                message: 'This is an informational message.',
                type: MitzoneFeedbackType.info,
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneFeedbackBanner(
                title: 'Success',
                message: 'Operation completed successfully.',
                type: MitzoneFeedbackType.success,
              ),
              const SizedBox(height: AppSpacing.md),
              const MitzoneFeedbackBanner(
                title: 'Warning',
                message: 'Please review your settings.',
                type: MitzoneFeedbackType.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneFeedbackBanner(
                title: 'Error',
                message: 'An unexpected error occurred.',
                type: MitzoneFeedbackType.error,
                action: MitzoneButton(
                  text: 'Retry',
                  variant: MitzoneButtonVariant.tertiary,
                  fullWidth: false,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          _Section(
            title: 'Loading Indicators',
            children: [
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    MitzoneLoadingIndicator(),
                    SizedBox(width: AppSpacing.xxl),
                    MitzoneLoadingIndicator(compact: true),
                    SizedBox(width: AppSpacing.md),
                    Text('Compact'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const MitzoneLoadingIndicator(text: 'Loading connections...'),
            ],
          ),
          _Section(
            title: 'Empty State',
            children: [
              MitzoneEmptyState(
                title: 'No connections found',
                message: 'Go out and meet some people to see them here.',
                icon: Icons.people_outline,
                primaryAction: MitzoneButton(
                  text: 'Discover Places',
                  onPressed: () {},
                ),
              ),
            ],
          ),
          _Section(
            title: 'Confirmation Dialog',
            children: [
              MitzoneButton(
                text: 'Show Confirmation Dialog',
                variant: MitzoneButtonVariant.secondary,
                onPressed: () async {
                  final result = await MitzoneConfirmationDialog.show(
                    context,
                    title: 'Are you sure?',
                    message: 'This action cannot be undone.',
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Confirmed')),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Show Destructive Dialog',
                variant: MitzoneButtonVariant.destructive,
                onPressed: () async {
                  await MitzoneConfirmationDialog.show(
                    context,
                    title: 'Delete Item',
                    message: 'Are you absolutely sure you want to delete this?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xhu),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
        const SizedBox(height: AppSpacing.xhu),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
