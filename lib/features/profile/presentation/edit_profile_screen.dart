import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _newAvatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    _nameController = TextEditingController(text: profile?.displayName);
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

    try {
      final profile = ref.read(currentProfileProvider).value!;
      String? avatarUri = profile.avatarUri;

      if (_newAvatarPath != null) {
        final storage = ref.read(avatarStorageProvider);
        avatarUri = await storage.saveAvatar(
          identityId: profile.id,
          sourcePath: _newAvatarPath!,
        );
      }

      final updatedProfile = UserProfile(
        id: profile.id,
        displayName: _nameController.text.trim(),
        avatarUri: avatarUri,
        bio: profile.bio,
        city: profile.city,
        languages: profile.languages,
        interests: profile.interests,
        connectionGoal: profile.connectionGoal,
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
            content: Text("We couldn't save your profile. Please try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found.')));
    }

    ImageProvider? imageProvider;
    if (_newAvatarPath != null) {
      imageProvider = FileImage(File(_newAvatarPath!));
    } else if (profile.avatarUri != null) {
      imageProvider = FileImage(File(profile.avatarUri!));
    }

    return MitzonePageBody(
      title: 'Edit Profile',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Icon(
                            Icons.person_outline,
                            size: 60,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: 18,
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: _pickImage,
                        padding: EdgeInsets.zero,
                        tooltip: 'Change profile photo',
                      ),
                    ),
                  ),
                ],
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
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Name is required';
                if (trimmed.length < 2) return 'Minimum 2 characters';
                if (trimmed.length > 50) return 'Maximum 50 characters';
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
