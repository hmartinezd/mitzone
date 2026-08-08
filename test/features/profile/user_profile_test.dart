import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('JSON round trip', () {
      const profile = UserProfile(
        id: 'user-123',
        displayName: 'Hector',
        avatarUri: 'file:///path/to/avatar.png',
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.id, profile.id);
      expect(fromJson.displayName, profile.displayName);
      expect(fromJson.avatarUri, profile.avatarUri);
    });

    test('handles null avatarUri', () {
      const profile = UserProfile(id: '123', displayName: 'User');
      expect(profile.avatarUri, isNull);

      final json = profile.toJson();
      expect(json['avatarUri'], isNull);

      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.avatarUri, isNull);
    });
  });
}
