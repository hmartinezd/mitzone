import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/domain_error.dart';
import '../../profile/data/profile_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Text(
                  'Sign in',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _signIn,
                  child: busy
                      ? const CircularProgressIndicator()
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> _signIn() async {
    final e = email.text.trim();
    if (!e.contains('@') || password.text.isEmpty) {
      setState(() => error = 'Enter a valid email and password.');
      return;
    }
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      setState(() => error = 'Authentication is not configured.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    var profileLookupStarted = false;
    try {
      final session = await repo.signIn(email: e, password: password.text);
      ref.invalidate(authSessionProvider);
      profileLookupStarted = true;
      final profile = await (() async {
        try {
          return await ref
              .read(profileRepositoryProvider)
              .getProfile(session.user.id);
        } catch (exception, stackTrace) {
          debugPrint('Post-auth profile lookup failed: $exception');
          debugPrintStack(stackTrace: stackTrace);
          rethrow;
        }
      })();
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        context.go(profile == null ? AppRoutes.createProfile : AppRoutes.home);
      }
    } on DomainError catch (exception, stackTrace) {
      debugPrint(
        '${profileLookupStarted ? 'Post-auth profile flow' : 'Sign-in'} failed: '
        '$exception',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(
          () => error = profileLookupStarted
              ? 'We could not load your profile. Please try again.'
              : 'We could not sign you in. Check your details and try again.',
        );
      }
    } catch (exception, stackTrace) {
      debugPrint(
        '${profileLookupStarted ? 'Post-auth profile flow' : 'Sign-in'} failed: '
        '$exception',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(
          () => error = profileLookupStarted
              ? 'We could not load your profile. Please try again.'
              : 'Authentication is temporarily unavailable.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
