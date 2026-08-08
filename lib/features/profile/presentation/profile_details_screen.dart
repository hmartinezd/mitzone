import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';
import '../domain/profile_validation.dart';

class ProfileDetailsScreen extends ConsumerWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return MitzonePageBody(
            title: 'Profile Details',
            onBack: () => context.pop(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your profile could not be found.'),
                  const SizedBox(height: AppSpacing.md),
                  MitzoneButton(
                    text: 'Finish your profile',
                    onPressed: () => context.go(AppRoutes.createProfile),
                  ),
                ],
              ),
            ),
          );
        }
        return ProfileDetailsForm(profile: profile);
      },
      loading: () => const MitzonePageBody(
        title: 'Profile Details',
        child: Center(child: MitzoneLoadingIndicator()),
      ),
      error: (error, stack) => MitzonePageBody(
        title: 'Profile Details',
        onBack: () => context.pop(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("We couldn't load your profile details."),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Try again',
                onPressed: () => ref.invalidate(currentProfileProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDetailsForm extends ConsumerStatefulWidget {
  const ProfileDetailsForm({
    required this.profile,
    super.key,
  });

  final UserProfile profile;

  @override
  ConsumerState<ProfileDetailsForm> createState() => _ProfileDetailsFormState();
}

class _ProfileDetailsFormState extends ConsumerState<ProfileDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _interestsController;
  late TextEditingController _languagesController;
  ConnectionGoal? _connectionGoal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.profile.bio);
    _cityController = TextEditingController(text: widget.profile.city);
    _interestsController = TextEditingController(
      text: widget.profile.interests.join(', '),
    );
    _languagesController = TextEditingController(
      text: widget.profile.languages.join(', '),
    );
    _connectionGoal = widget.profile.connectionGoal;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _interestsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  String? _validateList(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final items = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (items.length > ProfileValidation.maxListItems) {
      return 'Add up to ${ProfileValidation.maxListItems} $label.';
    }
    
    for (final item in items) {
      if (item.length > ProfileValidation.maxListItemLength) {
        return 'Each $label must be ${ProfileValidation.maxListItemLength} characters or fewer.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final rawLanguages = _languagesController.text.split(',').map((e) => e.trim()).toList();
      final rawInterests = _interestsController.text.split(',').map((e) => e.trim()).toList();

      final updatedProfile = UserProfile(
        id: widget.profile.id,
        displayName: widget.profile.displayName,
        avatarUri: widget.profile.avatarUri,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        languages: ProfileValidation.normalizeList(rawLanguages),
        interests: ProfileValidation.normalizeList(rawInterests),
        connectionGoal: _connectionGoal,
      );

      await ref.read(profileRepositoryProvider).saveProfile(updatedProfile);

      ref.invalidate(currentProfileProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("We couldn't save your details. Please try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MitzonePageBody(
      title: 'Profile Details',
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'These details are optional and help shape better connections.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself',
                helperText: '${_bioController.text.length}/${ProfileValidation.maxBioLength}',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: ProfileValidation.maxBioLength,
              onChanged: (text) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Where are you based?',
              ),
              maxLength: ProfileValidation.maxCityLength,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Interests
            TextFormField(
              key: const Key('interests_field'),
              controller: _interestsController,
              decoration: const InputDecoration(
                labelText: 'Interests',
                hintText: 'Music, Technology, Travel...',
                helperText: 'Separate with commas (max ${ProfileValidation.maxListItems})',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => _validateList(value, 'interests'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Languages
            TextFormField(
              key: const Key('languages_field'),
              controller: _languagesController,
              decoration: const InputDecoration(
                labelText: 'Languages',
                hintText: 'English, Spanish...',
                helperText: 'Separate with commas (max ${ProfileValidation.maxListItems})',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => _validateList(value, 'languages'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Connection Goal
            Text(
              'Connection Goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Using Wrap for better responsiveness with large text/narrow screens
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _GoalChip(
                  label: 'Not set',
                  selected: _connectionGoal == null,
                  onSelected: (selected) => setState(() => _connectionGoal = null),
                ),
                _GoalChip(
                  label: 'Social',
                  selected: _connectionGoal == ConnectionGoal.social,
                  onSelected: (selected) => setState(() => _connectionGoal = ConnectionGoal.social),
                ),
                _GoalChip(
                  label: 'Professional',
                  selected: _connectionGoal == ConnectionGoal.professional,
                  onSelected: (selected) => setState(() => _connectionGoal = ConnectionGoal.professional),
                ),
                _GoalChip(
                  label: 'Both',
                  selected: _connectionGoal == ConnectionGoal.both,
                  onSelected: (selected) => setState(() => _connectionGoal = ConnectionGoal.both),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxl),
            MitzoneButton(
              text: 'Save Details',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            MitzoneButton(
              text: 'Cancel',
              onPressed: () => context.pop(),
              variant: MitzoneButtonVariant.secondary,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      // Ensure minimum touch target size
      visualDensity: VisualDensity.standard,
    );
  }
}
