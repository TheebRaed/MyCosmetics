import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide ProductImageRepository, ProductRepository;
import 'package:mycosmetics_server/src/repositories/product_image_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

/// Reconstructed: this file previously held a stray duplicate of
/// AuthGuard/UnauthorizedException/ForbiddenException (removed by
/// mycosmetics-security -- the canonical version lives in
/// lib/src/utils/auth_guard.dart, which every endpoint already depends on).
/// This is the real ProductImageService, written to match the call sites
/// already present in endpoints/product_image_endpoint.dart
/// (listForProduct, add, delete) and following the same
/// repository-delegation + CatalogValidator pattern as the sibling catalog
/// services (CategoryService, BrandService, ProductVariantService).
class ProductImageService {
  final ProductImageRepository _images = ProductImageRepository();
  final ProductRepository _products = ProductRepository();

  Future<List<ProductImage>> listForProduct(Session session, int productId) {
    return _images.listForProduct(session, productId);
  }

  Future<List<ProductImage>> listForVariant(Session session, int variantId) {
    return _images.listForVariant(session, variantId);
  }

  Future<ProductImage> add(
    Session session, {
    required int productId,
    required String url,
    int? variantId,
    int sortOrder = 0,
  }) async {
    CatalogValidator.validateUrl(url, 'Product image URL');

    final product = await _products.findById(session, productId, includeInactive: true);
    if (product == null) {
      throw CatalogValidationException('Product not found.');
    }

    return _images.create(
      session,
      ProductImage(
        productId: productId,
        variantId: variantId,
        url: url,
        sortOrder: sortOrder,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> delete(Session session, {required int id, required int productId}) async {
    final existing = await _images.findById(session, id);
    if (existing == null || existing.productId != productId) {
      throw CatalogValidationException('Product image not found.');
    }
    await _images.delete(session, id);
  }
}
