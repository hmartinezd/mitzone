import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  String? error;
  bool loading = false;
  bool success = false;
  @override void dispose() { password.dispose(); confirmation.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(success ? 'Password updated' : 'Set a new password', style: Theme.of(context).textTheme.headlineSmall),
    if (success) const Text('You can now return to Mitzone and sign in.') else if (ref.watch(authSessionProvider).value == null) const Text('This reset link is invalid or expired. Request a new one from Sign in.') else ...[
      const SizedBox(height: 24),
      MitzoneTextField(controller: password, label: 'New password', obscureText: true),
      const SizedBox(height: 16),
      MitzoneTextField(controller: confirmation, label: 'Confirm password', obscureText: true),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 24),
      MitzoneButton(text: 'Update password', isLoading: loading, onPressed: loading ? null : _submit),
    ],
  ]))));
  Future<void> _submit() async {
    if (password.text.length < 6) { setState(() => error = 'Password must be at least 6 characters.'); return; }
    if (password.text != confirmation.text) { setState(() => error = 'Passwords do not match.'); return; }
    setState(() { loading = true; error = null; });
    if (ref.read(authSessionProvider).value == null) { setState(() => error = 'This reset link is invalid or expired.'); return; }
    try { await ref.read(authRepositoryProvider)!.updatePassword(password.text); if (mounted) { ref.invalidate(passwordRecoveryEventProvider); setState(() { loading = false; success = true; }); } }
    catch (_) { if (mounted) setState(() { loading = false; error = 'We could not update your password. Please try again.'; }); }
  }
}
