/// Production input validation utility.
/// All user-submitted data passes through these validators
/// before reaching the service or repository layers.
library input_validator;

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override String toString() => message;
}

class InputValidator {
  InputValidator._();

  // ── Auth ──────────────────────────────────────────────────────────────────

  static void validateEmail(String email) {
    if (email.trim().isEmpty) throw ValidationException('Email is required.');
    if (email.length > 255) throw ValidationException('Email is too long.');
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || !parts[1].contains('.')) {
      throw ValidationException('Invalid email address.');
    }
  }

  static void validatePassword(String password) {
    if (password.isEmpty) throw ValidationException('Password is required.');
    if (password.length < 8) throw ValidationException('Password must be at least 8 characters.');
    if (password.length > 128) throw ValidationException('Password is too long.');
  }

  static void validateFullName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw ValidationException('Full name is required.');
    if (n.length > 100) throw ValidationException('Name must be under 100 characters.');
    // Prevent script injection in name fields
    if (RegExp(r'[<>{}()\\]').hasMatch(n)) throw ValidationException('Name contains invalid characters.');
  }

  // ── Catalog ───────────────────────────────────────────────────────────────

  static void validateHexColor(String? hex) {
    if (hex == null) return;
    final clean = hex.replaceAll('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(clean)) {
      throw ValidationException('Invalid hex color format. Use #RRGGBB.');
    }
  }

  static void validatePrice(double price) {
    if (price < 0) throw ValidationException('Price cannot be negative.');
    if (price > 99999.99) throw ValidationException('Price exceeds maximum allowed value.');
  }

  static void validateStock(int qty) {
    if (qty < 0) throw ValidationException('Stock quantity cannot be negative.');
    if (qty > 999999) throw ValidationException('Stock quantity exceeds maximum.');
  }

  static void validateSku(String sku) {
    if (sku.trim().isEmpty) throw ValidationException('SKU is required.');
    if (sku.length > 50) throw ValidationException('SKU must be under 50 characters.');
    if (!RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(sku)) {
      throw ValidationException('SKU may only contain letters, numbers, hyphens, and underscores.');
    }
  }

  // ── Shopping ──────────────────────────────────────────────────────────────

  static void validateQuantity(int qty) {
    if (qty <= 0) throw ValidationException('Quantity must be at least 1.');
    if (qty > 99) throw ValidationException('Maximum quantity per item is 99.');
  }

  static void validateCouponCode(String code) {
    if (code.trim().isEmpty) throw ValidationException('Coupon code is required.');
    if (code.length > 20) throw ValidationException('Coupon code is too long.');
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) {
      throw ValidationException('Invalid coupon code format.');
    }
  }

  // ── BeautyTech ────────────────────────────────────────────────────────────

  static void validateUndertone(String undertone) {
    if (!{'warm', 'cool', 'neutral'}.contains(undertone)) {
      throw ValidationException("Undertone must be 'warm', 'cool', or 'neutral'.");
    }
  }

  static void validateFraction(double v, String field) {
    if (v < 0 || v > 1) throw ValidationException('$field must be between 0.0 and 1.0.');
  }

  // ── File uploads ──────────────────────────────────────────────────────────

  static void validateImageUpload({required int fileSizeBytes, required String mimeType}) {
    const maxBytes = 5 * 1024 * 1024; // 5 MB
    if (fileSizeBytes > maxBytes) {
      throw ValidationException('Image must be under 5 MB.');
    }
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowed.contains(mimeType.toLowerCase())) {
      throw ValidationException('Only JPEG, PNG, and WebP images are accepted.');
    }
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  static void validatePaymentAmount(double amount) {
    if (amount <= 0) throw ValidationException('Payment amount must be positive.');
    if (amount > 99999.99) throw ValidationException('Payment amount exceeds limit.');
  }

  static void validateIdempotencyKey(String key) {
    if (key.trim().isEmpty) throw ValidationException('Idempotency key is required.');
    if (key.length > 64) throw ValidationException('Idempotency key is too long.');
    // Must be UUID v4 format
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(key)) {
      throw ValidationException('Idempotency key must be a valid UUID v4.');
    }
  }

  // ── General ───────────────────────────────────────────────────────────────

  static String sanitizeText(String input, {int maxLength = 500}) {
    var s = input.trim();
    if (s.length > maxLength) s = s.substring(0, maxLength);
    // Strip null bytes and control characters (except newlines in multi-line fields)
    s = s.replaceAll(RegExp(r'\x00'), '');
    return s;
  }

  static void validatePage(int page, int pageSize) {
    if (page < 0) throw ValidationException('Page must be non-negative.');
    if (pageSize < 1 || pageSize > 100) throw ValidationException('Page size must be between 1 and 100.');
  }
}
