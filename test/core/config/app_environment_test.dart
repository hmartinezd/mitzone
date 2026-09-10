import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/errors/app_exception.dart';

void main() {
  group('AppEnvironment', () {
    test('fromString parses valid environments correctly', () {
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
      expect(
        AppEnvironment.fromString('DeVeLoPmEnT'),
        AppEnvironment.development,
      );
    });

    test('fromString handles whitespace', () {
      expect(
        AppEnvironment.fromString('  development  '),
        AppEnvironment.development,
      );
    });

    test('local is available only when explicitly enabled for tests', () {
      expect(
        AppEnvironment.fromString('local', allowLocal: true),
        AppEnvironment.local,
      );
      expect(
        () => AppEnvironment.fromString('local'),
        throwsA(isA<ConfigException>()),
      );
    });

    test(
      'fromString rejects unknown values instead of defaulting to local',
      () {
        expect(
          () => AppEnvironment.fromString('unknown'),
          throwsA(isA<ConfigException>()),
        );
        expect(
          () => AppEnvironment.fromString(''),
          throwsA(isA<ConfigException>()),
        );
        expect(
          () => AppEnvironment.fromString(null),
          throwsA(isA<ConfigException>()),
        );
      },
    );
  });
}
