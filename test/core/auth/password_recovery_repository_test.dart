import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitzone/core/auth/password_recovery.dart';
import 'package:mitzone/core/auth/supabase_auth_repository.dart';
import 'package:mitzone/core/errors/domain_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late SupabaseAuthRepository repository;
  late _MemoryPkceStorage storage;
  late List<http.Request> requests;
  late List<PasswordRecoveryState> states;
  late StreamSubscription<PasswordRecoveryState> subscription;
  late DateTime now;
  late Future<http.Response> Function(http.Request) respond;
  const user = {
    'id': 'recovery-user',
    'aud': 'authenticated',
    'email': 'person@example.com',
    'created_at': '2026-01-01T00:00:00Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  };

  Map<String, dynamic> session({String identity = 'recovery-user'}) {
    final header = base64Url
        .encode(utf8.encode('{"alg":"HS256"}'))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': identity,
              'exp':
                  now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                  1000,
            }),
          ),
        )
        .replaceAll('=', '');
    return {
      'access_token': '$header.$payload.test-signature',
      'refresh_token': 'test-refresh-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {...user, 'id': identity},
    };
  }

  setUp(() {
    now = DateTime.now().toUtc();
    requests = [];
    states = [];
    storage = _MemoryPkceStorage();
    respond = (request) async {
      if (request.url.path.endsWith('/token')) {
        return http.Response(jsonEncode(session()), 200);
      }
      if (request.url.path.endsWith('/user')) {
        return http.Response(jsonEncode({'user': user}), 200);
      }
      return http.Response('{}', 200);
    };
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-publishable-key',
      authOptions: AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false,
        pkceAsyncStorage: storage,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
    repository = SupabaseAuthRepository(client, clock: () => now);
    subscription = repository.passwordRecoveryStates.listen(states.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await repository.dispose();
    await client.dispose();
  });

  Future<void> requestAndRecover() async {
    await repository.requestPasswordReset('person@example.com');
    await repository.handleAuthLink(
      Uri.parse('$passwordRecoveryRedirect?code=test-code'),
    );
    await Future<void>.value();
    expect(
      await repository.passwordRecoveryStates.first,
      PasswordRecoveryState.ready,
    );
  }

  test(
    'request sends trimmed email, allowlisted redirect and S256 challenge, never password',
    () async {
      await repository.requestPasswordReset(' person@example.com ');
      final request = requests.single;
      expect(request.url.path, '/auth/v1/recover');
      expect(
        request.url.queryParameters['redirect_to'],
        passwordRecoveryRedirect,
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'person@example.com');
      expect(body['code_challenge_method'], 's256');
      expect(body['code_challenge'], isNotEmpty);
      expect(body.containsKey('password'), isFalse);
      expect(storage.values.values.single, endsWith('/passwordRecovery'));
    },
  );

  test(
    'unknown accounts receive the same acknowledgement without provider details',
    () async {
      respond = (_) async => http.Response(
        jsonEncode({
          'error_code': 'user_not_found',
          'msg': 'Private provider account details',
        }),
        400,
      );
      await expectLater(
        repository.requestPasswordReset('unknown@example.com'),
        completes,
      );
    },
  );

  test('network and rate errors expose safe actionable messages', () async {
    respond = (_) async => http.Response(
      jsonEncode({
        'error_code': 'over_email_send_rate_limit',
        'msg': 'Private provider details',
      }),
      429,
    );
    await expectLater(
      repository.requestPasswordReset('person@example.com'),
      throwsA(
        isA<DomainError>().having(
          (e) => e.message,
          'message',
          contains('wait a minute'),
        ),
      ),
    );
    now = now.add(const Duration(minutes: 1));
    respond = (_) async => throw http.ClientException('secret-provider-error');
    await expectLater(
      repository.requestPasswordReset('person@example.com'),
      throwsA(
        isA<DomainError>().having(
          (e) => e.message,
          'message',
          isNot(contains('secret')),
        ),
      ),
    );
  });

  test(
    'repeated requests are serialized and rate limited without replacing verifier',
    () async {
      final pending = Completer<http.Response>();
      respond = (_) => pending.future;
      final first = repository.requestPasswordReset('person@example.com');
      await Future<void>.value();
      await expectLater(
        repository.requestPasswordReset('person@example.com'),
        throwsA(isA<DomainError>()),
      );
      pending.complete(http.Response('{}', 200));
      await first;
      final verifier = Map.of(storage.values);
      await expectLater(
        repository.requestPasswordReset('person@example.com'),
        throwsA(isA<DomainError>()),
      );
      expect(storage.values, verifier);
      expect(requests, hasLength(1));
    },
  );

  test(
    'ordinary signed-in sessions cannot update passwords through recovery',
    () async {
      await client.auth.signInWithPassword(
        email: 'person@example.com',
        password: 'test-password',
      );
      expect(await repository.restoreSession(), isNotNull);
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test(
    'only validated recovery PKCE exchange grants one password update',
    () async {
      await requestAndRecover();
      final exchange = requests.last;
      expect(exchange.url.queryParameters['grant_type'], 'pkce');
      final body = jsonDecode(exchange.body) as Map<String, dynamic>;
      expect(body['auth_code'], 'test-code');
      expect(body['code_verifier'], isNotEmpty);
      expect(storage.values, isEmpty);
      await repository.updatePassword('new-password');
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.completed,
      );
      expect(jsonDecode(requests.last.body)['password'], 'new-password');
      await expectLater(
        repository.updatePassword('another-password'),
        throwsA(isA<DomainError>()),
      );
      await repository.signOut();
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.idle,
      );
      expect(await repository.restoreSession(), isNull);
    },
  );

  test(
    'sign-out during code exchange cannot reauthorize a stale recovery operation',
    () async {
      await repository.requestPasswordReset('person@example.com');
      final pending = Completer<http.Response>();
      final started = Completer<void>();
      respond = (_) {
        started.complete();
        return pending.future;
      };
      final exchange = repository.handleAuthLink(
        Uri.parse('$passwordRecoveryRedirect?code=in-flight'),
      );
      await started.future;
      await repository.signOut();
      pending.complete(http.Response(jsonEncode(session()), 200));
      await exchange;
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.invalid,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test(
    'ordinary PKCE sign-in code on reset path does not grant recovery',
    () async {
      await client.auth.signInWithOtp(email: 'person@example.com');
      await repository.handleAuthLink(
        Uri.parse('$passwordRecoveryRedirect?code=normal-sign-in'),
      );
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.invalid,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
    },
  );

  test(
    'forged token fragments, wrong host and missing code never authorize recovery',
    () async {
      await repository.handleAuthLink(
        Uri.parse('mitzone://evil/reset-password?code=bad'),
      );
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.idle,
      );
      for (final uri in [
        passwordRecoveryRedirect,
        '$passwordRecoveryRedirect#access_token=fake&refresh_token=fake&type=recovery',
        '$passwordRecoveryRedirect?type=recovery',
      ]) {
        await repository.handleAuthLink(Uri.parse(uri));
        await Future<void>.value();
        expect(
          await repository.passwordRecoveryStates.first,
          PasswordRecoveryState.invalid,
        );
      }
      expect(requests, isEmpty);
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
    },
  );

  test(
    'expired redirect and failed exchange have distinct safe states',
    () async {
      await repository.handleAuthLink(
        Uri.parse(
          '$passwordRecoveryRedirect?error=access_denied&error_code=otp_expired&error_description=secret',
        ),
      );
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.expired,
      );
      await repository.handleAuthLink(
        Uri.parse('$passwordRecoveryRedirect?code=without-verifier'),
      );
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.invalid,
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'expired-link errors in URL fragments never authorize a password update',
    () async {
      await repository.handleAuthLink(
        Uri.parse(
          '$passwordRecoveryRedirect#error=access_denied&error_code=otp_expired',
        ),
      );
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.expired,
      );
      expect(requests, isEmpty);
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
    },
  );

  test('replayed codes cannot use an existing session', () async {
    await requestAndRecover();
    await repository.handleAuthLink(
      Uri.parse('$passwordRecoveryRedirect?code=test-code'),
    );
    await Future<void>.value();
    expect(
      await repository.passwordRecoveryStates.first,
      PasswordRecoveryState.invalid,
    );
    await expectLater(
      repository.updatePassword('new-password'),
      throwsA(isA<DomainError>()),
    );
  });

  test('expired recovery session revokes authorization', () async {
    await requestAndRecover();
    now = now.add(const Duration(hours: 2));
    await expectLater(
      repository.updatePassword('new-password'),
      throwsA(isA<DomainError>()),
    );
    await Future<void>.value();
    expect(
      await repository.passwordRecoveryStates.first,
      PasswordRecoveryState.expired,
    );
  });

  test(
    'signing in as a different identity revokes recovery before mutation',
    () async {
      await requestAndRecover();
      respond = (_) async =>
          http.Response(jsonEncode(session(identity: 'other-user')), 200);
      await client.auth.signInWithPassword(
        email: 'other@example.com',
        password: 'test-password',
      );
      await Future<void>.value();
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test(
    'same password error preserves retry without exposing provider messages',
    () async {
      await requestAndRecover();
      respond = (_) async => http.Response(
        jsonEncode({
          'error_code': 'same_password',
          'msg': 'private-provider-message',
        }),
        422,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(
          isA<DomainError>().having(
            (e) => e.message,
            'message',
            contains('different password'),
          ),
        ),
      );
      await Future<void>.value();
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.ready,
      );
    },
  );

  test('weak server password policy is actionable and allows retry', () async {
    await requestAndRecover();
    respond = (_) async => http.Response(
      jsonEncode({
        'error_code': 'weak_password',
        'msg': 'private-provider-message',
        'weak_password': {
          'reasons': ['length'],
        },
      }),
      422,
    );
    await expectLater(
      repository.updatePassword('short'),
      throwsA(
        isA<DomainError>().having(
          (e) => e.message,
          'message',
          contains('stronger password'),
        ),
      ),
    );
    expect(
      await repository.passwordRecoveryStates.first,
      PasswordRecoveryState.ready,
    );
    expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
  });

  test(
    'server rejects expired code and no password mutation follows',
    () async {
      await repository.requestPasswordReset('person@example.com');
      respond = (_) async => http.Response(
        jsonEncode({
          'error_code': 'otp_expired',
          'msg': 'private-provider-message',
        }),
        400,
      );
      await repository.handleAuthLink(
        Uri.parse('$passwordRecoveryRedirect?code=expired'),
      );
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.expired,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test(
    'server session rejection expires the grant rather than permitting retries',
    () async {
      await requestAndRecover();
      respond = (_) async => http.Response(
        jsonEncode({
          'error_code': 'session_not_found',
          'msg': 'private-provider-message',
        }),
        401,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.expired,
      );
      await expectLater(
        repository.updatePassword('another-password'),
        throwsA(isA<DomainError>()),
      );
      expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
    },
  );

  test(
    'recovery authorization expires automatically while the form is open',
    () {
      fakeAsync((async) {
        // Construct the complete SDK harness in the controlled zone. Its auth
        // stream and HTTP futures must share the timer's clock.
        final timerClient = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: AuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            autoRefreshToken: false,
            pkceAsyncStorage: _MemoryPkceStorage(),
          ),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/token')) {
              return http.Response(jsonEncode(session()), 200);
            }
            return http.Response('{}', 200);
          }),
        );
        final timerRepository = SupabaseAuthRepository(
          timerClient,
          clock: () => now,
        );
        PasswordRecoveryState? result;
        final timerSubscription = timerRepository.passwordRecoveryStates.listen(
          (state) => result = state,
        );
        var recovered = false;
        timerRepository
            .requestPasswordReset('person@example.com')
            .then(
              (_) => timerRepository.handleAuthLink(
                Uri.parse('$passwordRecoveryRedirect?code=timer-test'),
              ),
            )
            .then((_) => recovered = true);
        async.flushMicrotasks();
        expect(recovered, isTrue);
        now = now.add(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));
        async.flushMicrotasks();
        expect(result, PasswordRecoveryState.expired);
        unawaited(timerSubscription.cancel());
        unawaited(timerRepository.dispose());
        unawaited(timerClient.dispose());
        async.flushMicrotasks();
        expect(async.pendingTimers, isEmpty);
      });
    },
  );

  test(
    'ordinary registration callback still signs in without recovery authority',
    () async {
      await client.auth.signInWithOtp(email: 'person@example.com');
      await repository.handleAuthLink(
        Uri.parse('mitzone://auth/callback?code=sign-up'),
      );
      expect(await repository.restoreSession(), isNotNull);
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.idle,
      );
      await expectLater(
        repository.updatePassword('new-password'),
        throwsA(isA<DomainError>()),
      );
    },
  );

  test('concurrent updates cannot issue a second mutation', () async {
    await requestAndRecover();
    final pending = Completer<http.Response>();
    respond = (_) => pending.future;
    final update = repository.updatePassword('new-password');
    await Future<void>.value();
    await expectLater(
      repository.updatePassword('another-password'),
      throwsA(isA<DomainError>()),
    );
    pending.complete(http.Response(jsonEncode({'user': user}), 200));
    await update;
    expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
  });

  test(
    'cold-start stream grants are replayed to later provider listeners',
    () async {
      final links = StreamController<Uri>();
      repository.startLinkHandling(
        links: links.stream,
        initialLink: () async => null,
      );
      await repository.requestPasswordReset('person@example.com');
      links.add(Uri.parse('$passwordRecoveryRedirect?code=cold-start'));
      await repository.passwordRecoveryStates.firstWhere(
        (state) => state == PasswordRecoveryState.ready,
      );
      expect(
        await repository.passwordRecoveryStates.first,
        PasswordRecoveryState.ready,
      );
      expect(
        requests.where((r) => r.url.path.endsWith('/token')),
        hasLength(1),
      );
      await links.close();
    },
  );
}

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}
