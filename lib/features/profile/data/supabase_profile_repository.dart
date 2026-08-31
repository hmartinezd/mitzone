import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';
import '../../../core/errors/domain_error.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.client);
  final SupabaseClient client;
  Map<String, dynamic> _row(UserProfile p) => {
    'id': p.id,
    'display_name': p.displayName,
    'avatar_uri': p.avatarUri,
    'bio': p.bio,
    'city': p.city,
    'languages': p.languages,
    'interests': p.interests,
    'connection_goal': p.connectionGoal?.name,
  };
  UserProfile _profile(Map<String, dynamic> r) => UserProfile(
    id: r['id'] as String,
    displayName: r['display_name'] as String,
    avatarUri: r['avatar_uri'] as String?,
    bio: r['bio'] as String?,
    city: r['city'] as String?,
    languages: (r['languages'] as List? ?? []).whereType<String>().toList(),
    interests: (r['interests'] as List? ?? []).whereType<String>().toList(),
    connectionGoal: ConnectionGoal.fromJson(r['connection_goal'] as String?),
  );
  @override
  Future<UserProfile?> getProfile(String id) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _profile(row);
  }

  Future<Map<String, UserProfile>> getProfilesByIds(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await client
        .from('profiles')
        .select()
        .inFilter('id', ids.toList());
    return {for (final row in rows) row['id'] as String: _profile(row)};
  }

  void _requireOwner(String id) {
    if (client.auth.currentUser?.id != id) {
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'Profile ownership mismatch',
      );
    }
  }

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    _requireOwner(identityId);
    return saveProfile(
      UserProfile(
        id: identityId,
        displayName: displayName,
        avatarUri: avatarUri,
      ),
    );
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    _requireOwner(profile.id);
    final row = await client
        .from('profiles')
        .upsert(_row(profile))
        .select()
        .single();
    return _profile(row);
  }
}
