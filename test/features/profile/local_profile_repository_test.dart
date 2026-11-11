import 'dart:convert';

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

    test('malformed required profile fields return null', () async {
      final malformedProfiles = <Map<String, dynamic>>[
        {'displayName': 'Hector'},
        {'id': '', 'displayName': 'Hector'},
        {'id': 'id-1'},
        {'id': 'id-1', 'displayName': 'H'},
      ];

      for (final json in malformedProfiles) {
        await storage.setString('local_profile.v1.id-1', jsonEncode(json));
        expect(await repository.getProfile('id-1'), isNull);
      }
    });

    test(
      'minimum then extended profile reload preserves identity and fields',
      () async {
        await repository.saveMinimumProfile(
          identityId: 'id-1',
          displayName: 'Hector',
        );
        await repository.saveProfile(
          const UserProfile(
            id: 'id-1',
            displayName: 'Hector Updated',
            avatarUri: '/managed/avatar.png',
            bio: 'Developer',
            city: 'Tampa',
            languages: ['English', 'Spanish'],
            interests: ['Flutter'],
            connectionGoal: ConnectionGoal.professional,
          ),
        );

        final reloadedRepository = LocalProfileRepository(storage);
        final profile = await reloadedRepository.getProfile('id-1');

        expect(profile?.id, 'id-1');
        expect(profile?.displayName, 'Hector Updated');
        expect(profile?.avatarUri, '/managed/avatar.png');
        expect(profile?.bio, 'Developer');
        expect(profile?.city, 'Tampa');
        expect(profile?.languages, ['English', 'Spanish']);
        expect(profile?.interests, ['Flutter']);
        expect(profile?.connectionGoal, ConnectionGoal.professional);
      },
    );

    test('returns null if profile does not exist', () async {
      final profile = await repository.getProfile('non-existent');
      expect(profile, isNull);
    });
  });
}
