import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('JSON round trip', () {
      const profile = UserProfile(
        id: 'user-123',
        displayName: 'Hector',
        avatarUri: 'file:///path/to/avatar.png',
        bio: 'Hello world',
        city: 'Tampa',
        languages: ['English', 'Spanish'],
        interests: ['Tech', 'Music'],
        connectionGoal: ConnectionGoal.both,
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.id, profile.id);
      expect(fromJson.displayName, profile.displayName);
      expect(fromJson.avatarUri, profile.avatarUri);
      expect(fromJson.bio, profile.bio);
      expect(fromJson.city, profile.city);
      expect(fromJson.languages, profile.languages);
      expect(fromJson.interests, profile.interests);
      expect(fromJson.connectionGoal, profile.connectionGoal);
    });

    test('JSON backward compatibility', () {
      final oldJson = {'id': 'abc', 'displayName': 'Hector', 'avatarUri': null};

      final profile = UserProfile.fromJson(oldJson);

      expect(profile.id, 'abc');
      expect(profile.displayName, 'Hector');
      expect(profile.bio, isNull);
      expect(profile.city, isNull);
      expect(profile.languages, isEmpty);
      expect(profile.interests, isEmpty);
      expect(profile.connectionGoal, isNull);
    });

    test('handles malformed optional JSON', () {
      final badJson = {
        'id': 'abc',
        'displayName': 'Hector',
        'languages': 'English', // Should be list
        'interests': 123, // Should be list
        'connectionGoal': 'unknown', // Should be ConnectionGoal enum name
      };

      final profile = UserProfile.fromJson(badJson);

      expect(profile.languages, isEmpty);
      expect(profile.interests, isEmpty);
      expect(profile.connectionGoal, isNull);
    });

    test('completion percentage calculation', () {
      expect(
        const UserProfile(id: '1', displayName: 'H').completionPercentage,
        14,
      ); // 1/7
      expect(
        const UserProfile(
          id: '1',
          displayName: 'H',
          avatarUri: 'x',
        ).completionPercentage,
        29,
      ); // 2/7

      const full = UserProfile(
        id: '1',
        displayName: 'H',
        avatarUri: 'x',
        bio: 'b',
        city: 'c',
        languages: ['l'],
        interests: ['i'],
        connectionGoal: ConnectionGoal.social,
      );
      expect(full.completionPercentage, 100);
    });
  });
}
