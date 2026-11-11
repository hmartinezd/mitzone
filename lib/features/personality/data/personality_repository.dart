import '../domain/personality_profile.dart';

abstract interface class PersonalityRepository {
  Future<PersonalityProfile?> getForUser(String userId);
  Future<PersonalityProfile> save(PersonalityProfile profile);
  Future<Map<String, double>> getCompatibilityWith(Set<String> ids);
}
