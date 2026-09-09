import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/domain_error.dart';
import '../../../shared/widgets/mitzone_brand.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_text_field.dart';
import '../../profile/data/profile_providers.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _isSubmitting = false;
  bool _showConfirmation = false;
  String? _errorMessage;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xxl * 2,
                  maxWidth: AppSpacing.maxContentWidthForm,
                ),
                child: Center(
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const MitzoneBrand(size: 60, showTagline: false),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_showConfirmation)
                          _buildConfirmation(theme)
                        else
                          _buildAuthenticationForm(theme),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSignUp ? 'Create your Mitzone account' : 'Welcome back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isSignUp
              ? 'Start with an account. You can complete your profile next.'
              : 'Sign in to continue to your connections.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildModeSelector(),
        const SizedBox(height: AppSpacing.xxl),
        MitzoneTextField(
          key: const ValueKey('auth-email'),
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          enabled: !_isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          prefixIcon: const Icon(Icons.mail_outline),
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: AppSpacing.lg),
        MitzoneTextField(
          key: ValueKey('auth-password-${_mode.name}'),
          controller: _passwordController,
          label: 'Password',
          helperText: _isSignUp
              ? 'Your password must meet Supabase account requirements.'
              : null,
          enabled: !_isSubmitting,
          obscureText: true,
          showObscureToggle: true,
          textInputAction: _isSignUp
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: [
            _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
          ],
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: (_) => _clearError(),
          onSubmitted: _isSignUp ? null : (_) => _submit(),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: AppSpacing.lg),
          MitzoneTextField(
            key: const ValueKey('auth-confirm-password'),
            controller: _confirmPasswordController,
            label: 'Confirm password',
            enabled: !_isSubmitting,
            obscureText: true,
            showObscureToggle: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            onChanged: (_) => _clearError(),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.lg),
          MitzoneFeedbackBanner(
            title: 'Could not continue',
            message: _errorMessage,
            type: MitzoneFeedbackType.error,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        MitzoneButton(
          text: _isSignUp ? 'Create Account' : 'Sign In',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Semantics(
      label: 'Authentication mode',
      child: SegmentedButton<_AuthMode>(
        segments: const [
          ButtonSegment<_AuthMode>(
            value: _AuthMode.signIn,
            label: Text('Sign In'),
            icon: Icon(Icons.login),
          ),
          ButtonSegment<_AuthMode>(
            value: _AuthMode.signUp,
            label: Text('Create Account'),
            icon: Icon(Icons.person_add_alt_1),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: _isSubmitting
            ? null
            : (selection) => _setMode(selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildConfirmation(ThemeData theme) {
    final email = _emailController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Check your email',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        MitzoneFeedbackBanner(
          title: 'Confirmation link sent',
          message:
              'We sent a confirmation link to $email. Confirm your email, '
              'then return to Mitzone to sign in.',
          type: MitzoneFeedbackType.success,
        ),
        const SizedBox(height: AppSpacing.xxl),
        MitzoneButton(
          text: 'Back to Sign In',
          variant: MitzoneButtonVariant.secondary,
          onPressed: _isSubmitting ? null : () => _setMode(_AuthMode.signIn),
        ),
      ],
    );
  }

  void _setMode(_AuthMode mode) {
    if (_isSubmitting) return;
    setState(() {
      _mode = mode;
      _showConfirmation = false;
      _errorMessage = null;
      if (mode == _AuthMode.signIn) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _clearError() {
    if (_errorMessage != null && mounted) {
      setState(() => _errorMessage = null);
    }
  }

  String? _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (_passwordController.text.isEmpty) return 'Password is required.';
    if (_isSignUp &&
        _passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      setState(() => _errorMessage = 'Authentication is not configured.');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final signingUp = _isSignUp;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var profileLookupStarted = false;
    try {
      if (signingUp) {
        final result = await repository.signUp(
          email: email,
          password: password,
        );
        if (!result.isSignedIn) {
          _passwordController.clear();
          _confirmPasswordController.clear();
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _showConfirmation = true;
            });
          }
          return;
        }
        final session = result.session;
        if (session == null) {
          throw const DomainError(
            DomainErrorCode.invalidState,
            'Authenticated signup returned no session.',
          );
        }
        profileLookupStarted = true;
        await _routeAfterAuthentication(session);
      } else {
        final session = await repository.signIn(
          email: email,
          password: password,
        );
        profileLookupStarted = true;
        await _routeAfterAuthentication(session);
      }
    } on DomainError catch (exception, stackTrace) {
      _logAuthFailure(signingUp, profileLookupStarted, exception, stackTrace);
      if (mounted) {
        setState(() => _errorMessage = _messageForDomainError(exception));
      }
    } catch (exception, stackTrace) {
      _logAuthFailure(signingUp, profileLookupStarted, exception, stackTrace);
      if (mounted) {
        setState(
          () => _errorMessage = profileLookupStarted
              ? 'We could not load your profile. Please try again.'
              : signingUp
              ? 'We could not create your account. Please try again.'
              : 'Authentication is temporarily unavailable.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _routeAfterAuthentication(AuthSession session) async {
    ref.invalidate(authSessionProvider);
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(session.user.id);
    ref.invalidate(currentProfileProvider);
    if (!mounted) return;
    context.go(profile == null ? AppRoutes.createProfile : AppRoutes.home);
  }

  String _messageForDomainError(DomainError error) {
    switch (error.code) {
      case DomainErrorCode.conflict:
        return 'An account already exists for this email address.';
      case DomainErrorCode.validation:
        return error.message;
      case DomainErrorCode.unauthorized:
        return _isSignUp
            ? 'We could not create your account. Please check your details and try again.'
            : 'We could not sign you in. Check your details and try again.';
      case DomainErrorCode.unavailable:
        return 'Authentication is temporarily unavailable.';
      case DomainErrorCode.notFound:
      case DomainErrorCode.interactionUnavailable:
      case DomainErrorCode.invalidState:
        return 'We could not complete that request. Please try again.';
    }
  }

  void _logAuthFailure(
    bool signingUp,
    bool profileLookupStarted,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '${signingUp ? 'Sign-up' : 'Sign-in'} '
      '${profileLookupStarted ? 'profile flow' : 'request'} failed: '
      '${error.runtimeType}',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}
