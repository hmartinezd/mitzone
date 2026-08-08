import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// An implementation of [ProfileRepository] that persists data in local storage.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._storage);

  final LocalStorage _storage;

  /// Returns the storage key for a specific profile ID.
  static String _profileKey(String id) => 'local_profile.v1.$id';

  @override
  Future<UserProfile?> getProfile(String identityId) async {
    final raw = await _storage.getString(_profileKey(identityId));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      // Malformed local data is treated as missing.
      return null;
    }
  }

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    final profile = UserProfile(
      id: identityId,
      displayName: displayName.trim(),
      avatarUri: avatarUri,
    );

    await _saveToStorage(profile);

    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _saveToStorage(profile);
    return profile;
  }

  Future<void> _saveToStorage(UserProfile profile) async {
    await _storage.setString(
      _profileKey(profile.id),
      jsonEncode(profile.toJson()),
    );
  }
}
