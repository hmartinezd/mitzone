import '../domain/user_profile.dart';

/// Interface for managing the user's profile data.
abstract interface class ProfileRepository {
  /// Retrieves the profile associated with the given [identityId].
  ///
  /// Returns null if no profile exists for this identity.
  Future<UserProfile?> getProfile(String identityId);

  /// Saves the minimum profile data for the user.
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  });

  /// Saves the full profile data.
  Future<UserProfile> saveProfile(UserProfile profile);
}

extension ProfileRepositoryBatch on ProfileRepository {
  Future<Map<String, UserProfile>> loadProfilesByIds(Set<String> ids) async {
    final profiles = <String, UserProfile>{};
    for (final id in ids) {
      final profile = await getProfile(id);
      if (profile != null) profiles[id] = profile;
    }
    return profiles;
  }
}
