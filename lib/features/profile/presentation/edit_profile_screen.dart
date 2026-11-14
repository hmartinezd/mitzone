import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';
import '../domain/profile_validation.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/profile_tags_field.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return MitzonePageBody(
            title: 'Edit Profile',
            onBack: () => context.pop(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your profile could not be found.'),
                  const SizedBox(height: AppSpacing.md),
                  MitzoneButton(
                    text: 'Try again',
                    onPressed: () => ref.invalidate(currentProfileProvider),
                  ),
                ],
              ),
            ),
          );
        }
        return EditProfileForm(profile: profile);
      },
      loading: () => MitzonePageBody(
        title: 'Edit Profile',
        onBack: () => context.pop(),
        child: const Center(child: MitzoneLoadingIndicator()),
      ),
      error: (error, stack) => MitzonePageBody(
        title: 'Edit Profile',
        onBack: () => context.pop(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("We couldn't load your profile."),
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

class EditProfileForm extends ConsumerStatefulWidget {
  const EditProfileForm({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _interestsController;
  late TextEditingController _languagesController;
  ConnectionGoal? _connectionGoal;
  String? _newAvatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
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
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _interestsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ref.read(avatarPickerProvider);
    try {
      final picked = await picker.pickFromGallery();
      if (picked != null) {
        setState(() => _newAvatarPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick image.')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final storage = ref.read(avatarStorageProvider);
    final oldAvatarUri = widget.profile.avatarUri;
    String? stagedAvatarUri;

    try {
      if (_newAvatarPath != null) {
        stagedAvatarUri = await storage.saveAvatar(
          identityId: widget.profile.id,
          sourcePath: _newAvatarPath!,
        );
      }

      final updatedProfile = UserProfile(
        id: widget.profile.id,
        displayName: _nameController.text.trim(),
        avatarUri: stagedAvatarUri ?? oldAvatarUri,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        languages: ProfileValidation.normalizeList(
          _languagesController.text.split(','),
        ),
        interests: ProfileValidation.normalizeList(
          _interestsController.text.split(','),
        ),
        connectionGoal: _connectionGoal,
      );

      await ref.read(profileRepositoryProvider).saveProfile(updatedProfile);
    } catch (e) {
      if (stagedAvatarUri != null) {
        await _bestEffortDelete(stagedAvatarUri);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("We couldn't save your profile. Please try again."),
          ),
        );
      }
      return;
    }

    // The profile is committed. Cleanup must not turn a successful save into
    // a failure or remove the newly active avatar.
    if (stagedAvatarUri != null && oldAvatarUri != null) {
      await _bestEffortDelete(oldAvatarUri);
    }

    ref.invalidate(currentProfileProvider);

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _bestEffortDelete(String avatarPath) async {
    try {
      await ref
          .read(avatarStorageProvider)
          .deleteAvatar(identityId: widget.profile.id, avatarPath: avatarPath);
    } catch (_) {
      // Avatar cleanup never changes the result of profile persistence.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MitzonePageBody(
      title: 'Edit Profile',
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ProfileAvatar(
                displayName: widget.profile.displayName,
                avatarUri: _newAvatarPath ?? widget.profile.avatarUri,
                radius: 36,
                onEdit: _pickImage,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Basic Identity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Enter your name',
                helperText: 'Visible to everyone on Mitzone',
                helperMaxLines: 3,
                errorMaxLines: 3,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (!ProfileValidation.isValidDisplayName(value)) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length <
                      ProfileValidation.minDisplayNameLength) {
                    return 'Minimum ${ProfileValidation.minDisplayNameLength} characters';
                  }
                  if (value.trim().length >
                      ProfileValidation.maxDisplayNameLength) {
                    return 'Maximum ${ProfileValidation.maxDisplayNameLength} characters';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('About you', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'These details are optional. Share only what you want other people to see.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: ProfileValidation.maxBioLength,
              validator: (value) => ProfileValidation.isValidBio(value)
                  ? null
                  : 'Bio is too long.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
              maxLength: ProfileValidation.maxCityLength,
              validator: (value) => ProfileValidation.isValidCity(value)
                  ? null
                  : 'City is too long.',
            ),
            const SizedBox(height: AppSpacing.md),
            ProfileTagsField(
              controller: _interestsController,
              label: 'Interests',
              singular: 'interest',
              fieldKey: const Key('interests_field'),
              suggestions: const [
                'Music',
                'Travel',
                'Technology',
                'Sports',
                'Art',
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ProfileTagsField(
              controller: _languagesController,
              label: 'Languages',
              singular: 'language',
              fieldKey: const Key('languages_field'),
              suggestions: const [
                'English',
                'Spanish',
                'French',
                'Portuguese',
                'German',
                'Italian',
                'Japanese',
                'Mandarin',
                'Arabic',
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Connection goal', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final option in <ConnectionGoal?, String>{
                  null: 'Not set',
                  ConnectionGoal.social: 'Social',
                  ConnectionGoal.professional: 'Professional',
                  ConnectionGoal.both: 'Both',
                }.entries)
                  ChoiceChip(
                    label: Text(option.value),
                    selected: _connectionGoal == option.key,
                    onSelected: _isSaving
                        ? null
                        : (_) => setState(() => _connectionGoal = option.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            MitzoneButton(
              text: 'Save Changes',
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
          ],
        ),
      ),
    );
  }
}
