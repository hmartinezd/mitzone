import '../domain/user_profile.dart';
import '../domain/public_profile.dart';

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

  Future<PublicProfile?> getPublicProfile(String userId) async {
    final profile = await getProfile(userId);
    return profile == null
        ? null
        : PublicProfile(
            id: profile.id,
            displayName: profile.displayName,
            avatarUri: profile.avatarUri,
            bio: profile.bio,
            city: profile.city,
          );
  }

  Future<Map<String, PublicProfile>> getPublicProfilesByIds(
    Set<String> userIds,
  ) async {
    final result = <String, PublicProfile>{};
    for (final id in userIds) {
      final profile = await getPublicProfile(id);
      if (profile != null) result[id] = profile;
    }
    return result;
  }
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
