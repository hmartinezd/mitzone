import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/domain_error.dart';
import '../domain/personality_profile.dart';
import 'personality_repository.dart';

class SupabasePersonalityRepository implements PersonalityRepository {
  SupabasePersonalityRepository(this.client);
  final SupabaseClient client;
  @override
  Future<PersonalityProfile?> getForUser(String userId) async {
    final row = await client
        .from('personality_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null
        ? null
        : PersonalityProfile.fromJson({
            ...row,
            'userId': row['user_id'],
            'version': row['questionnaire_version'],
            'completedAt': row['completed_at'],
            'visibility': row['visibility'],
          });
  }

  @override
  Future<PersonalityProfile> save(PersonalityProfile profile) async {
    if (client.auth.currentUser?.id != profile.userId)
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'You can only update your own personality profile.',
      );
    final row = {
      'user_id': profile.userId,
      'traits': profile.toJson()['traits'],
      'questionnaire_version': profile.version,
      'completed_at': profile.completedAt.toUtc().toIso8601String(),
      'visibility': profile.visibility,
    };
    await client.from('personality_profiles').upsert(row);
    return profile;
  }

  @override
  Future<Map<String, double>> getCompatibilityWith(Set<String> ids) async {
    final result = <String, double>{};
    for (final id in ids) {
      final row = await client.rpc(
        'get_personality_compatibility',
        params: {'p_other_user_id': id},
      );
      if (row is Map && row['state'] == 'known' && row['value'] is num)
        result[id] = (row['value'] as num).toDouble();
    }
    return result;
  }
}
