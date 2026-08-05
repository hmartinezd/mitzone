import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/errors/app_exception.dart';

void main() {
  group('AppConfig', () {
    test('local unconfigured mode when values are absent', () {
      final config = AppConfig.validated(env: AppEnvironment.local);
      expect(config.env, AppEnvironment.local);
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('accepts valid HTTP configuration', () {
      final config = AppConfig.validated(
        env: AppEnvironment.local,
        supabaseUrl: 'http://localhost:54321',
        supabasePublishableKey: 'some_key',
      );
      expect(config.isSupabaseConfigured, isTrue);
      expect(config.supabaseUrl, 'http://localhost:54321');
    });

    test('accepts valid HTTPS configuration', () {
      final config = AppConfig.validated(
        env: AppEnvironment.production,
        supabaseUrl: 'https://xyz.supabase.co',
        supabasePublishableKey: 'prod_key',
      );
      expect(config.isSupabaseConfigured, isTrue);
      expect(config.supabaseUrl, 'https://xyz.supabase.co');
    });

    test('throws ConfigException for URL without key', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'https://example.supabase.co',
        ),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains(
              'Both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided',
            ),
          ),
        ),
      );
    });

    test('throws ConfigException for key without URL', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabasePublishableKey: 'some_key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('treats whitespace-only values as absent', () {
      final config = AppConfig.validated(
        env: AppEnvironment.local,
        supabaseUrl: '  ',
        supabasePublishableKey: ' \t ',
      );
      expect(config.isSupabaseConfigured, isFalse);
      expect(config.supabaseUrl, isNull);
      expect(config.supabasePublishableKey, isNull);
    });

    test('rejects whitespace-only URL with a real key', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: '   ',
          supabasePublishableKey: 'real-key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects whitespace-only key with a real URL', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: '   ',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects invalid URL string', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'not-a-url',
          supabasePublishableKey: 'key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects relative URL', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: '/api/v1',
          supabasePublishableKey: 'key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects URL without host', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'https://',
          supabasePublishableKey: 'key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects FTP URL', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'ftp://example.com',
          supabasePublishableKey: 'key',
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('values are trimmed before storage', () {
      final config = AppConfig.validated(
        env: AppEnvironment.development,
        supabaseUrl: '  https://example.supabase.co  ',
        supabasePublishableKey: '  key_123  ',
      );
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabasePublishableKey, 'key_123');
    });

    test('toString() does not reveal the key', () {
      final config = AppConfig.validated(
        env: AppEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'secret_key_123',
      );
      expect(config.toString(), isNot(contains('secret_key_123')));
      expect(config.toString(), contains('supabaseConfigured: true'));
    });

    test('error messages do not reveal the key', () {
      try {
        AppConfig.validated(
          env: AppEnvironment.local,
          supabasePublishableKey: 'my_secret_key',
        );
        fail('Should have thrown ConfigException');
      } catch (e) {
        expect(e.toString(), isNot(contains('my_secret_key')));
      }
    });

    test('equality and hashCode', () {
      final config1 = AppConfig.validated(
        env: AppEnvironment.local,
        supabaseUrl: 'https://a.co',
        supabasePublishableKey: 'k',
      );
      final config2 = AppConfig.validated(
        env: AppEnvironment.local,
        supabaseUrl: 'https://a.co',
        supabasePublishableKey: 'k',
      );
      final config3 = AppConfig.validated(
        env: AppEnvironment.production,
        supabaseUrl: 'https://a.co',
        supabasePublishableKey: 'k',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });
  });
}
