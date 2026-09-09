import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'auth_models.dart';
import 'auth_repository.dart';
import '../errors/domain_error.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;

  AuthUser _mapUser(User user) => AuthUser(id: user.id, email: user.email);

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
  Future<void> signOut() => client.auth.signOut();
  @override
  Stream<AuthSession?> get sessionChanges =>
      client.auth.onAuthStateChange.map((event) => _map(event.session));
}
