import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class BrandRepository {
  Future<List<Brand>> listAll(Session session, {bool activeOnly = true}) {
    return Brand.db.find(
      session,
      where: (t) => activeOnly ? t.isActive.equals(true) : Constant.bool(true),
      orderBy: (t) => t.name,
    );
  }

  Future<Brand?> findById(Session session, int id) {
    return Brand.db.findById(session, id);
  }

  Future<Brand?> findBySlug(Session session, String slug) {
    return Brand.db.findFirstRow(session, where: (t) => t.slug.equals(slug));
  }

  Future<Brand> create(Session session, Brand brand) {
    return Brand.db.insertRow(session, brand);
  }

  Future<Brand> update(Session session, Brand brand) {
    return Brand.db.updateRow(session, brand);
  }

  Future<bool> hasProducts(Session session, int id) async {
    final products = await Product.db.find(
      session,
      where: (t) => t.brandId.equals(id) & t.deletedAt.equals(null),
      limit: 1,
    );
    return products.isNotEmpty;
  }

  Future<void> delete(Session session, int id) {
    return Brand.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }
}
