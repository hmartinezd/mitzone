import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/personality_profile.dart';
import 'personality_repository.dart';
class LocalPersonalityRepository implements PersonalityRepository {
  LocalPersonalityRepository(this.storage); final LocalStorage storage;
  String key(String id) => 'personality_profile.v1.$id';
  @override Future<PersonalityProfile?> getForUser(String userId) async { final raw = await storage.getString(key(userId)); return raw == null ? null : PersonalityProfile.fromJson(jsonDecode(raw)); }
  @override Future<PersonalityProfile> save(PersonalityProfile profile) async { await storage.setString(key(profile.userId), jsonEncode(profile.toJson())); return profile; }
  @override Future<Map<String, double>> getCompatibilityWith(Set<String> ids) async => {};
}
