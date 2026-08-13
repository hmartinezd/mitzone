import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'avatar_storage.dart';

/// An implementation of [AvatarStorage] that manages files in the app's local directory.
class LocalAvatarStorage implements AvatarStorage {
  LocalAvatarStorage({Future<Directory> Function()? supportDirectoryProvider})
    : _supportDirectoryProvider =
          supportDirectoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectoryProvider;

  @override
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  }) async {
    final avatarDir = await _managedIdentityDirectory(identityId);

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = p.join(avatarDir.path, 'avatar_$timestamp$extension');

    // Copy to managed storage to avoid dependency on temporary picker paths.
    await File(sourcePath).copy(targetPath);

    return targetPath;
  }

  @override
  Future<void> deleteAvatar({
    required String identityId,
    required String avatarPath,
  }) async {
    try {
      final avatarDir = p.canonicalize(
        (await _managedIdentityDirectory(identityId)).path,
      );
      final normalizedPath = p.canonicalize(p.absolute(avatarPath));

      // Security: Only delete files inside the identity-managed directory.
      if (!p.isWithin(avatarDir, normalizedPath)) {
        return;
      }

      final file = File(normalizedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Best-effort cleanup. Do not throw if deletion fails.
    }
  }

  Future<Directory> _managedIdentityDirectory(String identityId) async {
    final supportDirectory = await _supportDirectoryProvider();
    final avatarsRoot = p.canonicalize(
      p.absolute(p.join(supportDirectory.path, 'profile_avatars')),
    );
    final identityDirectory = p.canonicalize(
      p.absolute(p.join(avatarsRoot, identityId)),
    );

    if (!p.isWithin(avatarsRoot, identityDirectory)) {
      throw ArgumentError.value(identityId, 'identityId', 'Invalid identity');
    }

    return Directory(identityDirectory);
  }
}
