import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/password_recovery.dart';
import '../../../core/errors/domain_error.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_text_field.dart';
import 'recovery_layout.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authSessionProvider);
    final recovery = ref.watch(passwordRecoveryStateProvider);
    final state = recovery.value ?? PasswordRecoveryState.idle;
    ref.listen(passwordRecoveryStateProvider, (previous, next) {
      if (next.value != PasswordRecoveryState.ready) {
        _password.clear();
        _confirmation.clear();
      }
    });
    final checking =
        recovery.isLoading || state == PasswordRecoveryState.validating;
    final ready = state == PasswordRecoveryState.ready;
    final completed = state == PasswordRecoveryState.completed;
    final title = checking
        ? 'Checking recovery link'
        : completed
        ? 'Password updated'
        : ready
        ? 'Set a new password'
        : state == PasswordRecoveryState.expired
        ? 'Recovery link expired'
        : 'Invalid recovery link';

    return PopScope(
      canPop: false,
      child: RecoveryLayout(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (checking)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Validating recovery link',
              ),
            )
          else if (completed) ...[
            const Text(
              'Your password has been updated. Return to Sign in to continue with your new password.',
            ),
            const SizedBox(height: 24),
            MitzoneButton(
              text: 'Back to Sign In',
              isLoading: _loading,
              onPressed: _loading ? null : _backToLogin,
            ),
          ] else if (!ready) ...[
            Text(
              state == PasswordRecoveryState.expired
                  ? 'This recovery link or session has expired. Request a new email and open the latest link on this device.'
                  : 'This link could not be validated. Request a new email on this device and open its latest link in Mitzone.',
            ),
            const SizedBox(height: 24),
            MitzoneButton(
              text: 'Request a new link',
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
            TextButton(
              onPressed: _loading ? null : _backToLogin,
              child: const Text('Back to Sign In'),
            ),
          ] else ...[
            MitzoneTextField(
              key: const ValueKey('recovery-password'),
              controller: _password,
              label: 'New password',
              helperText:
                  'Your password must meet the account security requirements.',
              enabled: !_loading,
              obscureText: true,
              showObscureToggle: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            MitzoneTextField(
              key: const ValueKey('recovery-confirmation'),
              controller: _confirmation,
              label: 'Confirm password',
              enabled: !_loading,
              obscureText: true,
              showObscureToggle: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            MitzoneButton(
              text: 'Update password',
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
            TextButton(
              onPressed: _loading ? null : _backToLogin,
              child: const Text('Cancel recovery'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            MitzoneFeedbackBanner(
              title: 'Could not continue',
              message: _error,
              type: MitzoneFeedbackType.error,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _backToLogin() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider)?.signOut();
      if (!mounted) return;
      ref.invalidate(authSessionProvider);
      await ref.read(authSessionProvider.future);
      if (mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We could not end your session. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_loading ||
        ref.read(passwordRecoveryStateProvider).value !=
            PasswordRecoveryState.ready) {
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter a new password.');
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await repository.updatePassword(_password.text);
      if (!mounted) return;
      _password.clear();
      _confirmation.clear();
    } on DomainError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We could not update your password. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
