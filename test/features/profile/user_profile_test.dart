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
      // 1 character is invalid, so it should be 0/7
      expect(
        const UserProfile(id: '1', displayName: 'A').completionPercentage,
        0,
      );

      // 2 characters is valid, so 1/7
      expect(
        const UserProfile(id: '1', displayName: 'Jo').completionPercentage,
        14,
      );

      expect(
        const UserProfile(
          id: '1',
          displayName: 'Hector',
          avatarUri: 'x',
        ).completionPercentage,
        29,
      ); // 2/7

      const full = UserProfile(
        id: '1',
        displayName: 'Hector',
        avatarUri: 'x',
        bio: 'b',
        city: 'c',
        languages: ['l'],
        interests: ['i'],
        connectionGoal: ConnectionGoal.social,
      );
      expect(full.completionPercentage, 100);
    });

    test('defensive parsing of malformed list elements', () {
      final json = {
        'id': '1',
        'displayName': 'Hector',
        'languages': ['English', 123, null, 'Spanish'],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.languages, ['English', 'Spanish']);
    });

    test('reverts malformed optional scalars to null', () {
      final json = {
        'id': 'abc',
        'displayName': 'Hector',
        'avatarUri': 123,
        'bio': [],
        'city': {},
        'connectionGoal': 42,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.avatarUri, isNull);
      expect(profile.bio, isNull);
      expect(profile.city, isNull);
      expect(profile.connectionGoal, isNull);
    });

    group('strict required fields', () {
      test('throws FormatException for missing id', () {
        expect(
          () => UserProfile.fromJson({'displayName': 'Hector'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile id',
            ),
          ),
        );
      });

      test('throws FormatException for null id', () {
        expect(
          () => UserProfile.fromJson({'id': null, 'displayName': 'Hector'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile id',
            ),
          ),
        );
      });

      test('throws FormatException for non-string id', () {
        expect(
          () => UserProfile.fromJson({'id': 123, 'displayName': 'Hector'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile id',
            ),
          ),
        );
      });

      test('throws FormatException for blank id', () {
        expect(
          () => UserProfile.fromJson({'id': '  ', 'displayName': 'Hector'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile id',
            ),
          ),
        );
      });

      test('throws FormatException for missing displayName', () {
        expect(
          () => UserProfile.fromJson({'id': 'abc'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile display name',
            ),
          ),
        );
      });

      test('throws FormatException for null displayName', () {
        expect(
          () => UserProfile.fromJson({'id': 'abc', 'displayName': null}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile display name',
            ),
          ),
        );
      });

      test('throws FormatException for non-string displayName', () {
        expect(
          () => UserProfile.fromJson({'id': 'abc', 'displayName': 123}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile display name',
            ),
          ),
        );
      });

      test('throws FormatException for blank displayName', () {
        expect(
          () => UserProfile.fromJson({'id': 'abc', 'displayName': '  '}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile display name',
            ),
          ),
        );
      });

      test('throws FormatException for 1-character displayName', () {
        expect(
          () => UserProfile.fromJson({'id': 'abc', 'displayName': 'H'}),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid profile display name',
            ),
          ),
        );
      });
    });
  });
}
