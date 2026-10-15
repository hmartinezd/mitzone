import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'auth_models.dart';
import 'auth_repository.dart';
import 'password_recovery.dart';
import '../errors/domain_error.dart';

class SupabaseAuthRepository
    implements AuthRepository, PasswordRecoveryRepository {
  SupabaseAuthRepository(this.client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _authSubscription = client.auth.onAuthStateChange.listen(
      _onAuthChange,
      onError: (Object error, StackTrace stack) {
        if (_recoveryState == PasswordRecoveryState.ready ||
            _recoveryState == PasswordRecoveryState.validating) {
          _setRecoveryState(_linkFailureState(error));
        }
      },
    );
  }

  final SupabaseClient client;
  final DateTime Function() _clock;
  final _recoveryChanges = StreamController<PasswordRecoveryState>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  PasswordRecoveryState _recoveryState = PasswordRecoveryState.idle;
  String? _recoveryAccessToken;
  Timer? _expiryTimer;
  DateTime? _lastResetRequest;
  bool _requestingReset = false;
  bool _updatingPassword = false;
  bool _handlingLink = false;
  bool _disposed = false;
  int _generation = 0;

  void _setRecoveryState(PasswordRecoveryState state) {
    if (_disposed) return;
    _recoveryState = state;
    if (state != PasswordRecoveryState.ready) {
      _recoveryAccessToken = null;
      _expiryTimer?.cancel();
    }
    _recoveryChanges.add(state);
  }

  void _onAuthChange(AuthState change) {
    // A refreshed, replaced or signed-out session cannot inherit a previous
    // recovery grant. userUpdated is emitted by the password update itself.
    if (change.event == AuthChangeEvent.signedOut) {
      _generation++;
      _setRecoveryState(PasswordRecoveryState.idle);
    } else if (_recoveryState == PasswordRecoveryState.ready &&
        change.session?.accessToken != _recoveryAccessToken) {
      _generation++;
      _setRecoveryState(PasswordRecoveryState.expired);
    }
  }

  @override
  Stream<PasswordRecoveryState> get passwordRecoveryStates =>
      Stream.multi((sink) {
        final subscription = _recoveryChanges.stream.listen(
          sink.add,
          onDone: sink.close,
        );
        sink.add(_recoveryState);
        sink.onCancel = subscription.cancel;
      });

  void startLinkHandling({
    required Stream<Uri> links,
    required Future<Uri?> Function() initialLink,
  }) {
    // app_links includes the initial link in its stream. Using that one source
    // on mobile avoids exchanging a one-time PKCE code twice at cold start.
    _linkSubscription = links.listen(
      (uri) => unawaited(handleAuthLink(uri)),
      onError: (Object error, StackTrace stack) {
        _setRecoveryState(PasswordRecoveryState.invalid);
      },
    );
    if (kIsWeb) {
      unawaited(
        initialLink()
            .then((uri) async {
              if (uri != null) await handleAuthLink(uri);
            })
            .catchError((Object _) {
              _setRecoveryState(PasswordRecoveryState.invalid);
            }),
      );
    }
  }

  PasswordRecoveryState _linkFailureState(Object error) {
    if (error is AuthException &&
        (error.code == 'otp_expired' ||
            error.statusCode == 'otp_expired' ||
            error.code == 'session_expired' ||
            error.code == 'refresh_token_not_found')) {
      return PasswordRecoveryState.expired;
    }
    return PasswordRecoveryState.invalid;
  }

  Future<void> handleAuthLink(Uri uri) async {
    if (_disposed ||
        uri.scheme != 'mitzone' ||
        uri.host != 'auth' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return;
    }
    if (_handlingLink || _updatingPassword) return;
    final recovery = uri.path == '/reset-password';
    _handlingLink = true;
    final generation = _generation;
    if (recovery) _setRecoveryState(PasswordRecoveryState.validating);
    try {
      if (!recovery) {
        // Preserve existing registration/OAuth callbacks without granting
        // password recovery authority to an ordinary sign-in link.
        await client.auth.getSessionFromUrl(uri);
        return;
      }
      // Supabase can return redirect errors in a query or URL fragment.
      // Error parsing never grants authority to implicit token fragments.
      final parameters = {
        ...Uri.splitQueryString(uri.fragment),
        ...uri.queryParameters,
      };
      if (parameters.containsKey('error') ||
          parameters.containsKey('error_code')) {
        _setRecoveryState(
          parameters['error_code'] == 'otp_expired'
              ? PasswordRecoveryState.expired
              : PasswordRecoveryState.invalid,
        );
        return;
      }
      final code = uri.queryParameters['code'];
      // Recovery accepts only PKCE, never tokens or a caller-supplied type.
      // Supabase binds the recovery event to the locally stored verifier.
      if (code == null || code.isEmpty || uri.fragment.isNotEmpty) {
        _setRecoveryState(PasswordRecoveryState.invalid);
        return;
      }
      final result = await client.auth.exchangeCodeForSession(code);
      if (_disposed) return;
      if (generation != _generation) {
        _setRecoveryState(PasswordRecoveryState.invalid);
        return;
      }
      if (result.redirectType != AuthChangeEvent.passwordRecovery.name ||
          client.auth.currentSession?.accessToken !=
              result.session.accessToken) {
        _setRecoveryState(PasswordRecoveryState.invalid);
        return;
      }
      final expiresAt = result.session.expiresAt;
      final now = _clock().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt == null || expiresAt <= now) {
        _setRecoveryState(PasswordRecoveryState.expired);
        return;
      }
      _recoveryAccessToken = result.session.accessToken;
      _setRecoveryState(PasswordRecoveryState.ready);
      _expiryTimer = Timer(Duration(seconds: expiresAt - now), () {
        _setRecoveryState(PasswordRecoveryState.expired);
      });
    } catch (error) {
      if (recovery && !_disposed && generation == _generation) {
        _setRecoveryState(_linkFailureState(error));
      }
      // Auth URLs and provider errors may contain credentials. Never log them.
    } finally {
      _handlingLink = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _expiryTimer?.cancel();
    await _linkSubscription?.cancel();
    await _authSubscription.cancel();
    await _recoveryChanges.close();
  }

  AuthUser _mapUser(User user) => AuthUser(
    id: user.id,
    email: user.email,
    metadata: Map<String, dynamic>.from(user.userMetadata ?? const {}),
  );

  AuthSession? _map(Session? session) =>
      session == null ? null : AuthSession(user: _mapUser(session.user));

  void _logFailure(String operation, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    final details = error is AuthException
        ? 'status=${error.statusCode}, code=${error.code}'
        : 'type=${error.runtimeType}';
    developer.log(
      '$operation failed ($details)',
      name: 'mitzone.supabase_auth_repository',
      stackTrace: stackTrace,
    );
  }

  DomainError _mapError(Object error, {required bool isSignUp}) {
    if (error is AuthWeakPasswordException) {
      return const DomainError(
        DomainErrorCode.validation,
        'The password does not meet the account security requirements.',
      );
    }

    if (error is AuthApiException) {
      switch (error.code) {
        case 'user_already_exists':
        case 'email_exists':
          return const DomainError(
            DomainErrorCode.conflict,
            'An account already exists for this email address.',
          );
        case 'email_not_confirmed':
        case 'invalid_credentials':
          return const DomainError(
            DomainErrorCode.unauthorized,
            'The email or password is not correct.',
          );
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return const DomainError(
            DomainErrorCode.unavailable,
            'Too many attempts. Please wait a moment and try again.',
          );
      }
    }

    if (error is AuthRetryableFetchException) {
      return const DomainError(
        DomainErrorCode.unavailable,
        'Authentication is temporarily unavailable.',
      );
    }

    if (error is AuthException) {
      return DomainError(
        isSignUp ? DomainErrorCode.validation : DomainErrorCode.unauthorized,
        isSignUp
            ? 'We could not create your account. Please check your details and try again.'
            : 'We could not sign you in. Check your details and try again.',
      );
    }

    return const DomainError(
      DomainErrorCode.unavailable,
      'Authentication is temporarily unavailable.',
    );
  }

  @override
  Future<AuthSession?> restoreSession() async =>
      _map(client.auth.currentSession);
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = _map(
        (await client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        )).session,
      );
      if (session == null) {
        throw const DomainError(
          DomainErrorCode.unauthorized,
          'Authentication did not return a session',
        );
      }
      return session;
    } on DomainError {
      rethrow;
    } catch (error, stackTrace) {
      _logFailure('Sign-in', error, stackTrace);
      throw _mapError(error, isSignUp: false);
    }
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const DomainError(
          DomainErrorCode.invalidState,
          'Account creation did not return a user.',
        );
      }
      final session = _map(response.session);
      return AuthSignUpResult(
        user: _mapUser(user),
        session: session,
        outcome: session == null
            ? AuthSignUpOutcome.confirmationRequired
            : AuthSignUpOutcome.signedIn,
      );
    } on DomainError {
      rethrow;
    } catch (error, stackTrace) {
      _logFailure('Sign-up', error, stackTrace);
      throw _mapError(error, isSignUp: true);
    }
  }

  @override
  Future<void> signOut() async {
    _generation++;
    await client.auth.signOut();
    _setRecoveryState(PasswordRecoveryState.idle);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    if (_requestingReset ||
        (_lastResetRequest != null &&
            _clock().difference(_lastResetRequest!) <
                const Duration(minutes: 1))) {
      throw const DomainError(
        DomainErrorCode.unavailable,
        'Please wait a minute before requesting another recovery email.',
      );
    }
    _requestingReset = true;
    _lastResetRequest = _clock();
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: passwordRecoveryRedirect,
      );
    } on AuthException catch (error) {
      // Some server configurations return these errors for unknown accounts.
      // Present the identical acknowledgement, never the provider's message.
      if (error.code == 'user_not_found' || error.code == 'email_not_found') {
        return;
      }
      if (error.code == 'over_email_send_rate_limit' ||
          error.code == 'over_request_rate_limit') {
        throw const DomainError(
          DomainErrorCode.unavailable,
          'Please wait a minute before requesting another recovery email.',
        );
      }
      throw const DomainError(
        DomainErrorCode.unavailable,
        'We could not send recovery instructions. Please try again later.',
      );
    } catch (_) {
      throw const DomainError(
        DomainErrorCode.unavailable,
        'We could not send recovery instructions. Check your connection and try again later.',
      );
    } finally {
      _requestingReset = false;
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    final session = client.auth.currentSession;
    final expiresAt = session?.expiresAt;
    if (_updatingPassword) {
      throw const DomainError(
        DomainErrorCode.unavailable,
        'A password update is already in progress.',
      );
    }
    if (_recoveryState != PasswordRecoveryState.ready ||
        session == null ||
        session.accessToken != _recoveryAccessToken ||
        expiresAt == null ||
        expiresAt <= _clock().millisecondsSinceEpoch ~/ 1000) {
      if (_recoveryState == PasswordRecoveryState.ready) {
        _setRecoveryState(PasswordRecoveryState.expired);
      }
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'This recovery session is invalid or expired. Request a new link.',
      );
    }
    _updatingPassword = true;
    final generation = _generation;
    try {
      await client.auth.updateUser(UserAttributes(password: password));
      if (generation != _generation ||
          client.auth.currentSession?.accessToken != session.accessToken) {
        throw const DomainError(
          DomainErrorCode.unauthorized,
          'Your session changed. Sign in again to continue.',
        );
      }
      _setRecoveryState(PasswordRecoveryState.completed);
    } on AuthWeakPasswordException {
      throw const DomainError(
        DomainErrorCode.validation,
        'Your password does not meet the account security requirements. Choose a stronger password.',
      );
    } on AuthException catch (error) {
      if (error.code == 'same_password') {
        throw const DomainError(
          DomainErrorCode.validation,
          'Choose a different password from your current password.',
        );
      }
      if (error.statusCode == '401' || error.statusCode == '403') {
        _setRecoveryState(PasswordRecoveryState.expired);
        throw const DomainError(
          DomainErrorCode.unauthorized,
          'Your recovery session expired. Request a new link.',
        );
      }
      throw const DomainError(
        DomainErrorCode.unavailable,
        'We could not update your password. Please try again.',
      );
    } finally {
      _updatingPassword = false;
    }
  }

  @override
  Future<void> deleteAccount() async {
    await client.functions.invoke('delete-account');
    await client.auth.signOut();
  }

  @override
  Stream<AuthSession?> get sessionChanges =>
      client.auth.onAuthStateChange.map((event) => _map(event.session));
  @override
  Stream<bool> get recoveryEvents => passwordRecoveryStates.map(
    (state) => state == PasswordRecoveryState.ready,
  );
}
