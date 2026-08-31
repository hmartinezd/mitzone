import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../shared/widgets/mitzone_brand.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';
import '../../../shared/widgets/mitzone_text_field.dart';
import '../data/avatar_picker.dart';
import '../data/profile_providers.dart';
import '../../../core/auth/auth_providers.dart';

/// Screen for creating the user's initial local development profile.
class CreateMinimumProfileScreen extends ConsumerStatefulWidget {
  const CreateMinimumProfileScreen({super.key});

  @override
  ConsumerState<CreateMinimumProfileScreen> createState() =>
      _CreateMinimumProfileScreenState();
}

class _CreateMinimumProfileScreenState
    extends ConsumerState<CreateMinimumProfileScreen> {
  final _nameController = TextEditingController();
  PickedAvatar? _selectedAvatar;
  bool _isSaving = false;
  String? _errorMessage;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ref.read(avatarPickerProvider);
      final avatar = await picker.pickFromGallery();
      if (avatar != null) {
        setState(() => _selectedAvatar = avatar);
      }
    } catch (e) {
      setState(() => _errorMessage = "We couldn't open your gallery.");
    }
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Display name is required.';
    if (trimmed.length < 2) return 'Name must be at least 2 characters.';
    if (trimmed.length > 50) return 'Name must be 50 characters or less.';
    return null;
  }

  Future<void> _saveProfile() async {
    final nameError = _validateName(_nameController.text);
    if (nameError != null) {
      setState(() => _nameError = nameError);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _nameError = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final avatarStorage = ref.read(avatarStorageProvider);

      final session = await ref.read(authSessionProvider.future);
      final identityId =
          session?.user.id ??
          (await ref.read(identityGatewayProvider).ensureIdentity()).id;

      // 1. Save the minimum profile first (ensures core data is persisted)
      await profileRepo.saveMinimumProfile(
        identityId: identityId,
        displayName: _nameController.text.trim(),
        avatarUri: null,
      );

      // 2. Try to save the optional avatar if selected
      if (_selectedAvatar != null && !ref.read(productionModeProvider)) {
        try {
          final avatarUri = await avatarStorage.saveAvatar(
            identityId: identityId,
            sourcePath: _selectedAvatar!.path,
          );

          // Update profile with the new avatar URI
          await profileRepo.saveMinimumProfile(
            identityId: identityId,
            displayName: _nameController.text.trim(),
            avatarUri: avatarUri,
          );
        } catch (e) {
          // If avatar fails, we stop here and show the error, but the profile is already created.
          if (mounted) {
            setState(() {
              _isSaving = false;
              _errorMessage =
                  "Your profile was saved, but we couldn't save the photo. You can add one later.";
              _selectedAvatar = null; // Clear to allow continuing without it
            });
          }
          return;
        }
      }

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = "We couldn't save your profile. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MitzonePageScaffold(
      showAppBar: false,
      centered: true,
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const MitzoneBrand(size: 60, showTagline: false),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            "Let's make Mitzone yours.",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Choose the name people will see when you connect.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xhu),
          _AvatarPickerView(
            avatar: _selectedAvatar,
            onTap: _isSaving ? null : _pickAvatar,
          ),
          const SizedBox(height: AppSpacing.xxl),
          MitzoneTextField(
            label: 'Display name',
            hint: 'How should people see your name?',
            controller: _nameController,
            errorText: _nameError,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            MitzoneFeedbackBanner(
              title: _errorMessage!.startsWith('Your profile was saved')
                  ? 'Warning'
                  : 'Error',
              message: _errorMessage,
              type: _errorMessage!.startsWith('Your profile was saved')
                  ? MitzoneFeedbackType.warning
                  : MitzoneFeedbackType.error,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          MitzoneButton(
            text: 'Continue',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveProfile,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _AvatarPickerView extends StatelessWidget {
  const _AvatarPickerView({this.avatar, this.onTap});

  final PickedAvatar? avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: 'Choose profile photo',
        button: true,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.surfaceContainer,
              backgroundImage: avatar != null
                  ? FileImage(File(avatar!.path))
                  : null,
              child: avatar == null
                  ? Icon(
                      Icons.person_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
