/// Interface for persisting profile avatar images.
abstract interface class AvatarStorage {
  /// Saves an avatar image for the given [identityId] and returns its stored path/URI.
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  });
}
