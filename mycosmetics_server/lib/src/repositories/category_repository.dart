import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class CategoryRepository {
  Future<List<Category>> listTopLevel(Session session, {bool activeOnly = true}) {
    return Category.db.find(
      session,
      where: (t) => activeOnly
          ? (t.parentId.equals(null) & t.isActive.equals(true))
          : t.parentId.equals(null),
      orderBy: (t) => t.sortOrder,
    );
  }

  Future<List<Category>> listSubCategories(Session session, int parentId, {bool activeOnly = true}) {
    return Category.db.find(
      session,
      where: (t) => activeOnly
          ? (t.parentId.equals(parentId) & t.isActive.equals(true))
          : t.parentId.equals(parentId),
      orderBy: (t) => t.sortOrder,
    );
  }

  Future<Category?> findById(Session session, int id) {
    return Category.db.findById(session, id);
  }

  Future<Category?> findBySlug(Session session, String slug) {
    return Category.db.findFirstRow(session, where: (t) => t.slug.equals(slug));
  }

  /// Case-insensitive name lookup, used by RecommendationService to resolve
  /// a free-text `categoryFilter` (e.g. "Lipstick") into a categoryId.
  Future<Category?> findByNameCI(Session session, String name) async {
    final all = await Category.db.find(session, where: (t) => t.isActive.equals(true));
    final lower = name.trim().toLowerCase();
    for (final c in all) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  Future<Category> create(Session session, Category category) {
    return Category.db.insertRow(session, category);
  }

  Future<Category> update(Session session, Category category) {
    return Category.db.updateRow(session, category);
  }

  Future<bool> hasChildren(Session session, int id) async {
    final children = await Category.db.find(session, where: (t) => t.parentId.equals(id), limit: 1);
    return children.isNotEmpty;
  }

  Future<bool> hasProducts(Session session, int id) async {
    final products = await Product.db.find(
      session,
      where: (t) => t.categoryId.equals(id) & t.deletedAt.equals(null),
      limit: 1,
    );
    return products.isNotEmpty;
  }

  Future<void> delete(Session session, int id) {
    return Category.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }
}
