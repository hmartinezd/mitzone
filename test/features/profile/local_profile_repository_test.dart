import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/data/local_profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/core/storage/local_storage.dart';

class FakeLocalStorage implements LocalStorage {
  final Map<String, dynamic> data = {};

  @override
  Future<String?> getString(String key) async => data[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => data[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    data[key] = value;
  }
}

void main() {
  group('LocalProfileRepository', () {
    late FakeLocalStorage storage;
    late LocalProfileRepository repository;

    setUp(() {
      storage = FakeLocalStorage();
      repository = LocalProfileRepository(storage);
    });

    test('saveProfile persists all fields', () async {
      const profile = UserProfile(
        id: 'id-1',
        displayName: 'Hector',
        bio: 'Dev',
        city: 'Tampa',
        languages: ['English'],
        interests: ['Flutter'],
        connectionGoal: ConnectionGoal.social,
      );

      await repository.saveProfile(profile);

      final retrieved = await repository.getProfile('id-1');
      expect(retrieved?.displayName, 'Hector');
      expect(retrieved?.bio, 'Dev');
      expect(retrieved?.city, 'Tampa');
      expect(retrieved?.languages, ['English']);
      expect(retrieved?.interests, ['Flutter']);
      expect(retrieved?.connectionGoal, ConnectionGoal.social);
      expect(retrieved?.id, 'id-1');
    });

    test('saveMinimumProfile persists basic data and trims name', () async {
      await repository.saveMinimumProfile(
        identityId: 'id-1',
        displayName: ' Hector ',
      );

      final retrieved = await repository.getProfile('id-1');
      expect(retrieved?.displayName, 'Hector'); // Trims
      expect(retrieved?.id, 'id-1');
      expect(retrieved?.bio, isNull);
    });

    test('malformed JSON returns null instead of crashing', () async {
      await storage.setString('local_profile.v1.bad', 'not json');
      final profile = await repository.getProfile('bad');
      expect(profile, isNull);
    });

    test('returns null if profile does not exist', () async {
      final profile = await repository.getProfile('non-existent');
      expect(profile, isNull);
    });
  });
}
