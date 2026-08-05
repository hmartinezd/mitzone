import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('fromString parses valid environments correctly', () {
      expect(AppEnvironment.fromString('local'), AppEnvironment.local);
      expect(
        AppEnvironment.fromString('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(
        AppEnvironment.fromString('production'),
        AppEnvironment.production,
      );
    });

    test('fromString is case-insensitive', () {
      expect(AppEnvironment.fromString('LOCAL'), AppEnvironment.local);
      expect(
        AppEnvironment.fromString('DeVeLoPmEnT'),
        AppEnvironment.development,
      );
    });

    test('fromString handles whitespace', () {
      expect(AppEnvironment.fromString('  local  '), AppEnvironment.local);
    });

    test('fromString defaults to local for unknown values', () {
      expect(AppEnvironment.fromString('unknown'), AppEnvironment.local);
      expect(AppEnvironment.fromString(''), AppEnvironment.local);
      expect(AppEnvironment.fromString(null), AppEnvironment.local);
    });
  });
}
