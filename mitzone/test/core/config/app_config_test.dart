import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';

void main() {
  group('AppConfig', () {
    test('default configuration (no environment variables)', () {
      // In tests, String.fromEnvironment defaults to empty strings
      final config = AppConfig.fromEnvironment();

      expect(config.env, AppEnvironment.local);
      expect(config.supabaseUrl, isNull);
      expect(config.supabasePublishableKey, isNull);
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('manual instantiation with valid supabase config', () {
      const config = AppConfig(
        env: AppEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'some_key',
      );

      expect(config.isSupabaseConfigured, isTrue);
    });

    test(
      'manual instantiation with partial supabase config throws assertion error',
      () {
        expect(
          () => AppConfig(
            env: AppEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => AppConfig(
            env: AppEnvironment.development,
            supabasePublishableKey: 'some_key',
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
