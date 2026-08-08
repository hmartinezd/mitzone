import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/domain/profile_validation.dart';

void main() {
  group('ProfileValidation', () {
    test('isValidDisplayName', () {
      expect(ProfileValidation.isValidDisplayName('Hector'), isTrue);
      expect(ProfileValidation.isValidDisplayName('  Hector  '), isTrue);
      expect(ProfileValidation.isValidDisplayName('Jo'), isTrue); // 2 chars
      expect(ProfileValidation.isValidDisplayName('A' * 50), isTrue); // 50 chars
      
      expect(ProfileValidation.isValidDisplayName(''), isFalse);
      expect(ProfileValidation.isValidDisplayName(' '), isFalse);
      expect(ProfileValidation.isValidDisplayName('A'), isFalse); // 1 char
      expect(ProfileValidation.isValidDisplayName('A' * 51), isFalse); // 51 chars
      expect(ProfileValidation.isValidDisplayName(null), isFalse);
    });

    test('isValidBio', () {
      expect(ProfileValidation.isValidBio('Hello'), isTrue);
      expect(ProfileValidation.isValidBio('A' * 240), isTrue);
      expect(ProfileValidation.isValidBio('A' * 241), isFalse);
      expect(ProfileValidation.isValidBio(null), isTrue); // Optional
    });

    test('isValidListItem', () {
      expect(ProfileValidation.isValidListItem('Tech'), isTrue);
      expect(ProfileValidation.isValidListItem('A' * 30), isTrue);
      expect(ProfileValidation.isValidListItem('A' * 31), isFalse);
      expect(ProfileValidation.isValidListItem(''), isFalse);
      expect(ProfileValidation.isValidListItem(' '), isFalse);
    });

    test('normalizeList', () {
      final input = [' Tech ', '', 'MUSIC', 'music', '  Travel  ', 'TECH'];
      final output = ProfileValidation.normalizeList(input);
      
      expect(output, ['Tech', 'MUSIC', 'Travel']);
    });
    
    test('Unicode display names', () {
      expect(ProfileValidation.isValidDisplayName('José'), isTrue);
      expect(ProfileValidation.isValidDisplayName('Zoë'), isTrue);
      expect(ProfileValidation.isValidDisplayName('李雷'), isTrue);
      expect(ProfileValidation.isValidDisplayName('محمد'), isTrue);
    });
  });
}
