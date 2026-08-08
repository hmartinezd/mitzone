/// Represents the minimal profile information required for a Mitzone user.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUri,
  });

  /// The unique identifier associated with this profile (matching the identity ID).
  final String id;

  /// The name displayed to other users.
  final String displayName;

  /// A local or remote URI to the user's profile image.
  final String? avatarUri;

  /// Creates a [UserProfile] from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUri: json['avatarUri'] as String?,
    );
  }

  /// Converts this [UserProfile] into a JSON map.
  Map<String, dynamic> toJson() {
    return {'id': id, 'displayName': displayName, 'avatarUri': avatarUri};
  }
}
