import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'avatar_storage.dart';

/// An implementation of [AvatarStorage] that manages files in the app's local directory.
class LocalAvatarStorage implements AvatarStorage {
  @override
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final avatarDir = Directory(
      p.join(dir.path, 'profile_avatars', identityId),
    );

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
      final dir = await getApplicationSupportDirectory();
      final avatarDir = p.join(dir.path, 'profile_avatars', identityId);

      // Security: Only delete files inside the identity-managed directory.
      if (!p.isWithin(avatarDir, avatarPath)) {
        return;
      }

      final file = File(avatarPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Best-effort cleanup. Do not throw if deletion fails.
    }
  }
}
