import 'profile_validation.dart';

/// Supported connection goals for a user.
enum ConnectionGoal {
  social,
  professional,
  both;

  /// Converts the enum to a JSON-compatible string.
  String toJson() => name;

  /// Creates an enum from a JSON string, degrading gracefully for unknown values.
  static ConnectionGoal? fromJson(String? value) {
    if (value == null) return null;
    for (final goal in ConnectionGoal.values) {
      if (goal.name == value) return goal;
    }
    return null;
  }
}

/// Represents the profile information for a Mitzone user.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUri,
    this.bio,
    this.city,
    this.languages = const [],
    this.interests = const [],
    this.connectionGoal,
  });

  /// The unique identifier associated with this profile (matching the identity ID).
  final String id;

  /// The name displayed to other users.
  final String displayName;

  /// A local or remote URI to the user's profile image.
  final String? avatarUri;

  /// A short biography or description of the user.
  final String? bio;

  /// The user's current city.
  final String? city;

  /// A list of languages spoken by the user.
  final List<String> languages;

  /// A list of interests or hobbies.
  final List<String> interests;

  /// The primary goal for connecting on Mitzone.
  final ConnectionGoal? connectionGoal;

  /// Calculates the profile completion percentage based on 7 components.
  int get completionPercentage {
    int completed = 0;
    if (ProfileValidation.isValidDisplayName(displayName)) completed++;
    if (avatarUri != null && avatarUri!.isNotEmpty) completed++;
    if (bio != null && bio!.trim().isNotEmpty) completed++;
    if (city != null && city!.trim().isNotEmpty) completed++;
    if (languages.isNotEmpty) completed++;
    if (interests.isNotEmpty) completed++;
    if (connectionGoal != null) completed++;

    return (completed / 7 * 100).round();
  }

  /// Creates a [UserProfile] from a JSON map with defensive parsing.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] is String ? json['id'] as String : '',
      displayName: json['displayName'] is String ? json['displayName'] as String : 'Unknown',
      avatarUri: json['avatarUri'] is String ? json['avatarUri'] as String? : null,
      bio: json['bio'] is String ? json['bio'] as String? : null,
      city: json['city'] is String ? json['city'] as String? : null,
      languages: _parseList(json['languages']),
      interests: _parseList(json['interests']),
      connectionGoal: ConnectionGoal.fromJson(
        json['connectionGoal'] is String ? json['connectionGoal'] as String? : null,
      ),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  /// Converts this [UserProfile] into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUri': avatarUri,
      'bio': bio,
      'city': city,
      'languages': languages,
      'interests': interests,
      'connectionGoal': connectionGoal?.toJson(),
    };
  }
}
