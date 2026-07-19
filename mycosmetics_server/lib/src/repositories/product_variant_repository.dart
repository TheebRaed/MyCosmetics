import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ProductImageRepository {
  Future<List<ProductImage>> listForProduct(Session session, int productId) {
    return ProductImage.db.find(
      session,
      where: (t) => t.productId.equals(productId),
      orderBy: (t) => t.sortOrder,
    );
  }

  Future<List<ProductImage>> listForVariant(Session session, int variantId) {
    return ProductImage.db.find(
      session,
      where: (t) => t.variantId.equals(variantId),
      orderBy: (t) => t.sortOrder,
    );
  }

  Future<ProductImage?> findById(Session session, int id) {
    return ProductImage.db.findById(session, id);
  }

  Future<ProductImage> create(Session session, ProductImage image) {
    return ProductImage.db.insertRow(session, image);
  }

  Future<void> delete(Session session, int id) {
    return ProductImage.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }

  Future<void> deleteForProduct(Session session, int productId) {
    return ProductImage.db.deleteWhere(session, where: (t) => t.productId.equals(productId));
  }
}
