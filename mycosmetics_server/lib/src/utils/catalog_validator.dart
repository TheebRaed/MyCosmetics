class CatalogValidationException implements Exception {
  final String message;
  CatalogValidationException(this.message);
  @override
  String toString() => message;
}

class CatalogValidator {
  static final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
  static final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static void requireNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw CatalogValidationException('$fieldName is required.');
    }
  }

  static void validateSlug(String slug) {
    if (!_slugPattern.hasMatch(slug)) {
      throw CatalogValidationException(
        'Slug must be lowercase letters, numbers, and hyphens only (e.g. "matte-lipstick").',
      );
    }
  }

  static void validatePrice(double price, {String fieldName = 'Price'}) {
    if (price.isNaN || price.isInfinite || price < 0) {
      throw CatalogValidationException('$fieldName must be a non-negative number.');
    }
    if (price > 1000000) {
      throw CatalogValidationException('$fieldName exceeds the maximum allowed value.');
    }
  }

  static void validateStock(int stockQty) {
    if (stockQty < 0) {
      throw CatalogValidationException('Stock quantity cannot be negative.');
    }
  }

  static void validateHexColor(String? hex) {
    if (hex == null) return;
    if (!_hexColorPattern.hasMatch(hex)) {
      throw CatalogValidationException('hexColor must be a 6-digit hex code, e.g. "#C2185B".');
    }
  }

  static void validateRating(double rating) {
    if (rating < 0 || rating > 5) {
      throw CatalogValidationException('Rating must be between 0 and 5.');
    }
  }

  static void validatePagination(int page, int pageSize) {
    if (page < 0) {
      throw CatalogValidationException('Page must be 0 or greater.');
    }
    if (pageSize < 1 || pageSize > 100) {
      throw CatalogValidationException('Page size must be between 1 and 100.');
    }
  }

  static void validateUrl(String? url, String fieldName) {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      throw CatalogValidationException('$fieldName must be a valid http(s) URL.');
    }
  }
}
