import 'dart:io';
import 'package:flutter/material.dart';

/// A reusable avatar widget for Mitzone profiles.
///
/// Handles file safety for local avatar paths and provides accessible labels.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.displayName,
    super.key,
    this.avatarUri,
    this.radius = 50,
    this.onEdit,
    this.editIcon = Icons.photo_library_outlined,
  });

  /// The user's display name, used for semantic labels and placeholders.
  final String displayName;

  /// The local or remote URI for the avatar image.
  final String? avatarUri;

  /// The radius of the avatar.
  final double radius;

  /// Optional callback for editing the avatar.
  final VoidCallback? onEdit;

  /// The icon to show on the edit button.
  final IconData editIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ImageProvider? imageProvider;
    if (avatarUri != null && avatarUri!.isNotEmpty) {
      final file = File(avatarUri!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    final avatar = Semantics(
      label: 'Profile photo for $displayName',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainer,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(
                Icons.person_outline,
                size: radius,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
    );

    if (onEdit == null) {
      return avatar;
    }

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Change profile photo',
            child: SizedBox(
              key: const Key('profile_avatar_edit_target'),
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: (radius * 0.3).clamp(18, 24),
                      child: Icon(
                        editIcon,
                        size: (radius * 0.15).clamp(18, 20),
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
