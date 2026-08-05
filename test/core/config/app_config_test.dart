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

    test('accepts valid configuration', () {
      final config = AppConfig.validated(
        env: AppEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'some_key',
      );
      expect(config.isSupabaseConfigured, isTrue);
      expect(config.supabaseUrl, 'https://example.supabase.co');
    });

    test('throws ConfigException for partial configuration', () {
      expect(
        () => AppConfig.validated(
          env: AppEnvironment.local,
          supabaseUrl: 'https://example.supabase.co',
        ),
        throwsA(isA<ConfigException>()),
      );

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
    });

    test('rejects invalid URLs', () {
      void expectInvalid(String url) {
        expect(
          () => AppConfig.validated(
            env: AppEnvironment.local,
            supabaseUrl: url,
            supabasePublishableKey: 'key',
          ),
          throwsA(isA<ConfigException>()),
        );
      }

      expectInvalid('not-a-url');
      expectInvalid('ftp://example.com');
      expectInvalid('https://'); // no host
    });

    test('accepts http for local development', () {
      final config = AppConfig.validated(
        env: AppEnvironment.local,
        supabaseUrl: 'http://localhost:54321',
        supabasePublishableKey: 'key',
      );
      expect(config.isSupabaseConfigured, isTrue);
    });

    test('toString() does not contain the publishable key', () {
      final config = AppConfig.validated(
        env: AppEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'secret_key_123',
      );
      expect(config.toString(), isNot(contains('secret_key_123')));
      expect(config.toString(), contains('supabaseConfigured: true'));
    });

    test('ConfigException does not contain the publishable key', () {
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
  });
}
