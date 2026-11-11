/// Interface for persisting profile avatar images.
abstract interface class AvatarStorage {
  /// Saves an avatar image for the given [identityId] and returns its stored path/URI.
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  });

  /// Deletes an avatar file from managed storage.
  ///
  /// Only files confirmed to be within the identity's managed directory are deleted.
  Future<void> deleteAvatar({
    required String identityId,
    required String avatarPath,
  });
}
