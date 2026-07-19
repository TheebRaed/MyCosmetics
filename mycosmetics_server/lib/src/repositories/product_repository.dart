import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ProductVariantRepository {
  Future<List<ProductVariant>> listForProduct(Session session, int productId, {bool activeOnly = true}) {
    return ProductVariant.db.find(
      session,
      where: (t) => activeOnly
          ? (t.productId.equals(productId) & t.isActive.equals(true))
          : t.productId.equals(productId),
      orderBy: (t) => t.id,
    );
  }

  Future<ProductVariant?> findById(Session session, int id) {
    return ProductVariant.db.findById(session, id);
  }

  Future<ProductVariant?> findBySku(Session session, String sku) {
    return ProductVariant.db.findFirstRow(session, where: (t) => t.sku.equals(sku));
  }

  Future<ProductVariant> create(Session session, ProductVariant variant) {
    return ProductVariant.db.insertRow(session, variant);
  }

  Future<ProductVariant> update(Session session, ProductVariant variant) {
    return ProductVariant.db.updateRow(session, variant);
  }

  Future<void> delete(Session session, int id) {
    return ProductVariant.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }

  /// Cheapest active variant's price, used to keep Product.basePrice in
  /// sync ("starting at $X" display) whenever variants change.
  Future<double?> minActivePrice(Session session, int productId) async {
    final variants = await ProductVariant.db.find(
      session,
      where: (t) => t.productId.equals(productId) & t.isActive.equals(true),
      orderBy: (t) => t.price,
      limit: 1,
    );
    return variants.isEmpty ? null : variants.first.price;
  }
}
