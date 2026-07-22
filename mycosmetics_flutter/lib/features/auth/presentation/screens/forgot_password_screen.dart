import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_message_banner.dart';
import '../widgets/auth_scaffold.dart';

/// Collects the account email and triggers the reset-token flow
/// (`AuthEndpoint.forgotPassword`). The backend always returns success
/// regardless of whether the email exists (anti-enumeration -- see
/// mycosmetics_server/lib/src/business/auth_service.dart), so this screen
/// shows the same generic confirmation either way and never confirms or
/// denies an account exists.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = friendlyAuthErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AuthWordmark(fontSize: 32)),
          const SizedBox(height: AppSpacing.lg),
          Text('Reset your password', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _submitted
                ? "If an account exists for that email, we've sent a reset code to it."
                : "Enter the email on your account and we'll send you a reset code.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_submitted) ...[
            const AuthMessageBanner(message: 'Reset code requested.', isError: false),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: 'Enter Reset Code',
              expand: true,
              onPressed: () => context.push(AppRoutes.resetCode),
            ),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthMessageBanner(message: _errorMessage),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email address';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : PillButton(label: 'Send Reset Code', expand: true, onPressed: _submit),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
