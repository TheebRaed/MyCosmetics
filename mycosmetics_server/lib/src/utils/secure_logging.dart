const _sensitiveKeys = {'password','newPassword','currentPassword','token','passwordHash','rawToken','apiKey','secret'};
const _redacted = '[REDACTED]';

class SecureLogging {
  SecureLogging._();
  static Map<String,dynamic> sanitise(Map<String,dynamic>? params) {
    if (params == null) return {};
    return {for (final e in params.entries) e.key: _sensitiveKeys.contains(e.key.toLowerCase()) ? _redacted : e.value};
  }
  static void log(dynamic session, String message, {Map<String,dynamic>? context}) {
    final safe = sanitise(context);
    final line = safe.isEmpty ? message : '$message ${safe.toString()}';
    // ignore: avoid_dynamic_calls
    session.log(line);
  }
}
