import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/business/product_service.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

class ProductVariantService {
  final ProductVariantRepository _variants = ProductVariantRepository();
  final ProductRepository _products = ProductRepository();
  final ProductService _productService = ProductService();

  Future<List<ProductVariant>> listForProduct(Session session, int productId) {
    return _variants.listForProduct(session, productId);
  }

  Future<ProductVariant> create(
    Session session, {
    required int productId,
    required String sku,
    required double price,
    String? shadeName,
    String? hexColor,
    String? size,
    int stockQty = 0,
  }) async {
    CatalogValidator.requireNonEmpty(sku, 'SKU');
    CatalogValidator.validatePrice(price);
    CatalogValidator.validateStock(stockQty);
    CatalogValidator.validateHexColor(hexColor);

    final product = await _products.findById(session, productId, includeInactive: true);
    if (product == null) throw CatalogValidationException('Product not found.');

    final existingSku = await _variants.findBySku(session, sku);
    if (existingSku != null) {
      throw CatalogValidationException('A variant with this SKU already exists.');
    }

    final now = DateTime.now().toUtc();
    final variant = await _variants.create(
      session,
      ProductVariant(
        productId: productId,
        shadeName: shadeName,
        hexColor: hexColor,
        size: size,
        sku: sku,
        price: price,
        stockQty: stockQty,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _productService.syncBasePriceFromVariants(session, productId);
    return variant;
  }

  Future<ProductVariant> update(
    Session session, {
    required int id,
    double? price,
    int? stockQty,
    String? shadeName,
    String? hexColor,
    String? size,
    bool? isActive,
  }) async {
    final existing = await _variants.findById(session, id);
    if (existing == null) throw CatalogValidationException('Variant not found.');
    if (price != null) CatalogValidator.validatePrice(price);
    if (stockQty != null) CatalogValidator.validateStock(stockQty);
    if (hexColor != null) CatalogValidator.validateHexColor(hexColor);

    final updated = await _variants.update(
      session,
      existing.copyWith(
        price: price ?? existing.price,
        stockQty: stockQty ?? existing.stockQty,
        shadeName: shadeName ?? existing.shadeName,
        hexColor: hexColor ?? existing.hexColor,
        size: size ?? existing.size,
        isActive: isActive ?? existing.isActive,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    if (price != null || isActive != null) {
      await _productService.syncBasePriceFromVariants(session, existing.productId);
    }
    return updated;
  }

  Future<void> delete(Session session, int id) async {
    final existing = await _variants.findById(session, id);
    if (existing == null) throw CatalogValidationException('Variant not found.');
    await _variants.delete(session, id);
    await _productService.syncBasePriceFromVariants(session, existing.productId);
  }
}
