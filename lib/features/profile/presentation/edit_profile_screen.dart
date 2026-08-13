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
import 'widgets/profile_avatar.dart';

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
                    text: 'Finish your profile',
                    onPressed: () => context.go(AppRoutes.createProfile),
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
  String? _newAvatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        bio: widget.profile.bio,
        city: widget.profile.city,
        languages: widget.profile.languages,
        interests: widget.profile.interests,
        connectionGoal: widget.profile.connectionGoal,
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
                radius: 60,
                onEdit: _pickImage,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
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
            const SizedBox(height: AppSpacing.xxxl),
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
