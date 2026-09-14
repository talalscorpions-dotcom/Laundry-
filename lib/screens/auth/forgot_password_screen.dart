import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import '../../widgets/error_banner.dart';

/// Public route (see `AuthMiddleware`) — a two-step password reset: confirm
/// the account's email, then set a new password.
///
/// A real flow proves the visitor owns that email — a reset link with a
/// short-lived, single-use token, or a one-time code — before ever
/// accepting a new password. This demo has no email service to send that
/// link/code through, so step 2 is reachable as soon as the email is known
/// to exist; see the warning on `AppState.resetPassword` for why that
/// shortcut must not ship to production.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;
  bool _emailConfirmed = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailConfirmed ? _buildResetStep(context) : _buildEmailStep(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Enter the email on your account and we\'ll let you set a new password.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[ErrorBanner(message: _error!), const SizedBox(height: 16)],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submitEmail, child: const Text('Continue')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(BuildContext context) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_open_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Set a new password for ${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[ErrorBanner(message: _error!), const SizedBox(height: 16)],
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submitReset, child: const Text('Reset password')),
        ],
      ),
    );
  }

  void _submitEmail() {
    if (!_emailFormKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    if (!appState.accountExistsForEmail(_emailController.text)) {
      setState(() => _error = 'No account found for that email.');
      return;
    }
    setState(() {
      _error = null;
      _emailConfirmed = true;
    });
  }

  void _submitReset() {
    if (!_resetFormKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final result = appState.resetPassword(
      email: _emailController.text,
      newPassword: _newPasswordController.text,
    );
    if (!result.isSuccess) {
      setState(() => _error = result.error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated — sign in with your new password.')),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
  }
}
