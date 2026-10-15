import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/domain_error.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_text_field.dart';
import 'recovery_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecoveryLayout(
    children: [
      Text(
        'Reset your password',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      const Text(
        'Enter your email to request a recovery link. Open the link on this device in Mitzone.',
      ),
      const SizedBox(height: 24),
      MitzoneTextField(
        key: const ValueKey('recovery-email'),
        controller: _email,
        label: 'Email',
        enabled: !_loading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onSubmitted: (_) => _submit(),
        onChanged: (_) => setState(() {
          _error = null;
          _sent = false;
        }),
      ),
      if (_sent) ...[
        const SizedBox(height: 16),
        const MitzoneFeedbackBanner(
          title: 'Check your email',
          message:
              'If an account exists for this email, you will receive password reset instructions. Use the latest link; it expires.',
          type: MitzoneFeedbackType.success,
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
      const SizedBox(height: 24),
      MitzoneButton(
        text: _sent ? 'Send another email' : 'Send recovery email',
        isLoading: _loading,
        onPressed: _loading ? null : _submit,
      ),
      TextButton(
        onPressed: _loading ? null : _backToLogin,
        child: const Text('Back to Sign In'),
      ),
    ],
  );

  Future<void> _backToLogin() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // An invalid/expired callback may still have a Supabase session. End it
      // explicitly before returning to the ordinary sign-in route.
      if (ref.read(passwordRecoveryStateProvider).value?.blocksApp == true) {
        await ref.read(authRepositoryProvider)?.signOut();
        if (!mounted) return;
        ref.invalidate(authSessionProvider);
        await ref.read(authSessionProvider.future);
      }
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
    if (_loading) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      setState(() => _error = 'Password recovery is not configured.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _sent = false;
    });
    try {
      await repository.requestPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } on DomainError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We could not send recovery instructions. Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
