import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/repositories/product_image_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

class ProductImageService {
  final ProductImageRepository _images = ProductImageRepository();
  final ProductRepository _products = ProductRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();

  Future<List<ProductImage>> listForProduct(Session session, int productId) {
    return _images.listForProduct(session, productId);
  }

  Future<ProductImage> add(
    Session session, {
    required int productId,
    required String url,
    int? variantId,
    int sortOrder = 0,
  }) async {
    CatalogValidator.requireNonEmpty(url, 'Image URL');
    CatalogValidator.validateUrl(url, 'Image URL');

    final product = await _products.findById(session, productId, includeInactive: true);
    if (product == null) throw CatalogValidationException('Product not found.');

    if (variantId != null) {
      final variant = await _variants.findById(session, variantId);
      if (variant == null || variant.productId != productId) {
        throw CatalogValidationException('Variant does not belong to this product.');
      }
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
      throw CatalogValidationException('Image not found for this product.');
    }
    await _images.delete(session, id);
  }
}
