import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/utils/secure_logging.dart';

/// Minimal transactional-email integration point.
///
/// Reads SMTP settings from environment variables so nothing sensitive
/// lives in the repo (`config/*.yaml` is checked in). If SMTP isn't
/// configured (typical for local dev), delivery is skipped and a
/// redacted line is logged instead of failing the request -- forgotPassword
/// must stay a no-op-on-failure, account-enumeration-safe flow either way.
///
/// Env vars:
///   SMTP_HOST      -- required to actually send
///   SMTP_PORT      -- defaults to 465 (implicit TLS)
///   SMTP_USERNAME  -- SMTP auth username
///   SMTP_PASSWORD  -- SMTP auth password
///   SMTP_FROM      -- From: address, defaults to no-reply@mycosmetics.app
class EmailService {
  EmailService._();

  static bool get _isConfigured => (Platform.environment['SMTP_HOST'] ?? '').isNotEmpty;

  /// Sends the password-reset token to [toEmail]. The customer app's reset
  /// screen is a token-entry screen (not a deep-linked page), so the email
  /// carries the raw token as a short code the user copies in, plus a
  /// human-readable expiry notice.
  ///
  /// [resetToken] is only ever handled in-memory here and inside the SMTP
  /// payload sent directly to the provider -- it is never logged, never
  /// written to a file, and never returned to any caller.
  static Future<void> sendPasswordResetEmail(
    Session session, {
    required String toEmail,
    required String resetToken,
  }) async {
    const subject = 'Your MyCosmetics password reset code';
    final body = 'We received a request to reset your MyCosmetics password.\n\n'
        'Reset code: $resetToken\n\n'
        'Enter this code in the app to choose a new password. '
        'This code expires in 30 minutes and can only be used once.\n\n'
        "If you didn't request this, you can safely ignore this email.";

    if (!_isConfigured) {
      // Dev/local fallback: never log the token itself, only that dispatch
      // was skipped. Operators can grep for this to confirm SMTP isn't wired.
      SecureLogging.log(
        session,
        'EmailService: SMTP not configured, skipping password reset email dispatch.',
        context: {'toEmail': toEmail},
      );
      return;
    }

    try {
      await _sendSmtp(to: toEmail, subject: subject, body: body);
    } catch (e) {
      // Never let email transport failures leak the token or block the
      // generic-success response contract of forgotPassword; just log
      // (redacted) that delivery failed so it's visible in ops.
      SecureLogging.log(
        session,
        'EmailService: failed to send password reset email.',
        context: {'toEmail': toEmail, 'error': e.toString()},
      );
    }
  }

  static Future<void> _sendSmtp({
    required String to,
    required String subject,
    required String body,
  }) async {
    final host = Platform.environment['SMTP_HOST']!;
    final port = int.tryParse(Platform.environment['SMTP_PORT'] ?? '') ?? 465;
    final username = Platform.environment['SMTP_USERNAME'] ?? '';
    final password = Platform.environment['SMTP_PASSWORD'] ?? '';
    final from = Platform.environment['SMTP_FROM'] ?? 'no-reply@mycosmetics.app';

    final socket = await SecureSocket.connect(host, port, timeout: const Duration(seconds: 10));
    try {
      Future<String> read() async => await socket.cast<List<int>>().transform(utf8.decoder).first;
      void write(String line) => socket.write('$line\r\n');

      await read(); // greeting
      write('EHLO mycosmetics.app');
      await read();

      if (username.isNotEmpty) {
        write('AUTH LOGIN');
        await read();
        write(base64.encode(utf8.encode(username)));
        await read();
        write(base64.encode(utf8.encode(password)));
        await read();
      }

      write('MAIL FROM:<$from>');
      await read();
      write('RCPT TO:<$to>');
      await read();
      write('DATA');
      await read();
      write('From: MyCosmetics <$from>\r\n'
          'To: <$to>\r\n'
          'Subject: $subject\r\n'
          'Content-Type: text/plain; charset=UTF-8\r\n'
          '\r\n'
          '$body\r\n'
          '.');
      await read();
      write('QUIT');
    } finally {
      await socket.close();
    }
  }
}
