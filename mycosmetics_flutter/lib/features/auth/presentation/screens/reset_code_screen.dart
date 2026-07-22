import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../widgets/auth_message_banner.dart';
import '../widgets/auth_scaffold.dart';

/// Collects the password-reset token.
///
/// IMPORTANT backend-shape note: `AuthEndpoint.forgotPassword` does not
/// implement a short numeric OTP flow. It generates a single-use UUID
/// token (30-minute expiry, hashed at rest) meant to be delivered as a
/// reset *link* by email -- see
/// mycosmetics_server/lib/src/business/auth_service.dart
/// `requestPasswordReset`/`resetPassword`. Email delivery itself is a
/// TODO on the server (`AuthEndpoint.forgotPassword` currently only logs
/// the raw token server-side instead of sending it).
///
/// Until that's wired up, there's no way for a customer to receive this
/// token through the app. This screen is built to accept whatever string
/// token the user has (e.g. pasted from a reset link/email once that's
/// implemented) rather than a fictitious 6-digit OTP keypad, so it matches
/// what the backend actually does. Flag for mycosmetics-backend: either
/// wire real email delivery of the link (and skip this manual-entry screen
/// in favor of a deep link), or add a true short-code OTP path if that's
/// the desired UX -- the current DB model (`PasswordResetToken`) doesn't
/// support the latter without a schema change.
class ResetCodeScreen extends StatefulWidget {
  const ResetCodeScreen({super.key});

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    context.push(AppRoutes.resetPassword, extra: _codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AuthWordmark(fontSize: 32)),
            const SizedBox(height: AppSpacing.lg),
            Text('Enter your reset code', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paste the reset code from the email we sent you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            const AuthMessageBanner(
              message: 'Email delivery for reset codes is not live yet in this build -- check with support if you don\'t have one.',
              isError: false,
            ),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Reset code', prefixIcon: Icon(Icons.vpn_key_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Reset code is required' : null,
              onFieldSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(label: 'Continue', expand: true, onPressed: _continue),
          ],
        ),
      ),
    );
  }
}
