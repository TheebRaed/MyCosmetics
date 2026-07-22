class ShoppingValidationException implements Exception {
  final String message;
  ShoppingValidationException(this.message);
  @override
  String toString() => message;
}

class ShoppingValidator {
  static void validateQuantity(int quantity) {
    if (quantity < 1) {
      throw ShoppingValidationException('Quantity must be at least 1.');
    }
    if (quantity > 50) {
      throw ShoppingValidationException('Quantity exceeds the maximum allowed per item (50).');
    }
  }

  static void validateRating(int rating) {
    if (rating < 1 || rating > 5) {
      throw ShoppingValidationException('Rating must be between 1 and 5.');
    }
  }

  static void validateCouponCode(String code) {
    if (code.trim().isEmpty) {
      throw ShoppingValidationException('Coupon code is required.');
    }
  }

  static void validatePagination(int page, int pageSize) {
    if (page < 0) throw ShoppingValidationException('Page must be 0 or greater.');
    if (pageSize < 1 || pageSize > 100) {
      throw ShoppingValidationException('Page size must be between 1 and 100.');
    }
  }
}
