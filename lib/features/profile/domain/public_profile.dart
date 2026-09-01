import 'user_profile.dart';

/// The intentionally small profile projection safe for an authorized peer.
class PublicProfile {
  const PublicProfile({required this.id, required this.displayName, this.avatarUri, this.bio, this.city});
  final String id;
  final String displayName;
  final String? avatarUri;
  final String? bio;
  final String? city;

  factory PublicProfile.fromJson(Map<String, dynamic> row) => PublicProfile(
    id: row['id'] as String,
    displayName: row['display_name'] as String,
    avatarUri: row['avatar_uri'] as String?,
    bio: row['bio'] as String?,
    city: row['city'] as String?,
  );

  UserProfile toUserProfile() => UserProfile(
    id: id, displayName: displayName, avatarUri: avatarUri, bio: bio, city: city,
  );
}
