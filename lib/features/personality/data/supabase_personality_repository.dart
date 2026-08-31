import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/domain_error.dart';
import '../domain/personality_profile.dart';
import 'personality_repository.dart';
class SupabasePersonalityRepository implements PersonalityRepository {
  SupabasePersonalityRepository(this.client); final SupabaseClient client;
  @override Future<PersonalityProfile?> getForUser(String userId) async { final row = await client.from('personality_profiles').select().eq('user_id', userId).maybeSingle(); return row == null ? null : PersonalityProfile.fromJson({...row, 'userId': row['user_id'], 'completedAt': row['completed_at']}); }
  @override Future<PersonalityProfile> save(PersonalityProfile profile) async { if (client.auth.currentUser?.id != profile.userId) throw const DomainError(DomainErrorCode.unauthorized, 'You can only update your own personality profile.'); final row = {'user_id': profile.userId, 'traits': profile.toJson()['traits'], 'questionnaire_version': profile.version, 'completed_at': profile.completedAt.toUtc().toIso8601String(), 'visibility': profile.visibility}; await client.from('personality_profiles').upsert(row); return profile; }
  @override Future<Map<String, PersonalityProfile>> getByIds(Set<String> ids) async { if (ids.isEmpty) return {}; final rows = await client.from('personality_profiles').select().inFilter('user_id', ids.toList()); return {for (final row in rows) row['user_id'] as String: PersonalityProfile.fromJson({...row, 'userId': row['user_id'], 'completedAt': row['completed_at']})}; }
}
