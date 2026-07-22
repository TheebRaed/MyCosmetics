import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide CategoryRepository;
import 'package:mycosmetics_server/src/repositories/category_repository.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

class CategoryService {
  final CategoryRepository _categories = CategoryRepository();

  Future<List<Category>> listTopLevel(Session session) {
    return _categories.listTopLevel(session);
  }

  Future<List<Category>> listSubCategories(Session session, int parentId) {
    return _categories.listSubCategories(session, parentId);
  }

  Future<Category> create(
    Session session, {
    required String name,
    required String slug,
    int? parentId,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    CatalogValidator.requireNonEmpty(name, 'Category name');
    CatalogValidator.validateSlug(slug);
    CatalogValidator.validateUrl(imageUrl, 'Category image URL');

    final existingSlug = await _categories.findBySlug(session, slug);
    if (existingSlug != null) {
      throw CatalogValidationException('A category with this slug already exists.');
    }

    if (parentId != null) {
      final parent = await _categories.findById(session, parentId);
      if (parent == null) {
        throw CatalogValidationException('Parent category not found.');
      }
      // Enforce a single level of nesting (Category -> SubCategory only),
      // matching the documented Phase 2 scope even though the schema
      // technically allows deeper trees.
      if (parent.parentId != null) {
        throw CatalogValidationException('Sub-categories cannot have their own sub-categories.');
      }
    }

    final now = DateTime.now().toUtc();
    return _categories.create(
      session,
      Category(
        parentId: parentId,
        name: name.trim(),
        slug: slug,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Category> update(
    Session session, {
    required int id,
    String? name,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    final existing = await _categories.findById(session, id);
    if (existing == null) throw CatalogValidationException('Category not found.');
    if (imageUrl != null) CatalogValidator.validateUrl(imageUrl, 'Category image URL');

    return _categories.update(
      session,
      existing.copyWith(
        name: name?.trim() ?? existing.name,
        imageUrl: imageUrl ?? existing.imageUrl,
        sortOrder: sortOrder ?? existing.sortOrder,
        isActive: isActive ?? existing.isActive,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> delete(Session session, int id) async {
    final existing = await _categories.findById(session, id);
    if (existing == null) throw CatalogValidationException('Category not found.');

    if (await _categories.hasChildren(session, id)) {
      throw CatalogValidationException('Cannot delete a category that has sub-categories.');
    }
    if (await _categories.hasProducts(session, id)) {
      throw CatalogValidationException('Cannot delete a category that has products. Deactivate it instead.');
    }
    await _categories.delete(session, id);
  }
}
