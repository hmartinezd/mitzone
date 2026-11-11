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
}

/// Optional capability for repositories that can enforce a public-profile
/// boundary without reading private profile fields.
abstract interface class PublicProfileRepository {
  Future<PublicProfile?> getPublicProfile(String userId);
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(Set<String> ids);
}

extension ProfileRepositoryBatch on ProfileRepository {
  Future<PublicProfile?> getPublicProfile(String userId) async {
    if (this case final PublicProfileRepository repository) {
      return repository.getPublicProfile(userId);
    }
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
    Set<String> ids,
  ) async {
    if (this case final PublicProfileRepository repository) {
      return repository.getPublicProfilesByIds(ids);
    }
    final profiles = <String, PublicProfile>{};
    for (final id in ids) {
      final profile = await getPublicProfile(id);
      if (profile != null) {
        profiles[id] = profile;
      }
    }
    return profiles;
  }

  Future<Map<String, UserProfile>> loadProfilesByIds(Set<String> ids) async {
    final publicProfiles = await getPublicProfilesByIds(ids);
    return {
      for (final profile in publicProfiles.values)
        profile.id: UserProfile(
          id: profile.id,
          displayName: profile.displayName,
          avatarUri: profile.avatarUri,
          bio: profile.bio,
          city: profile.city,
        ),
    };
  }
}
