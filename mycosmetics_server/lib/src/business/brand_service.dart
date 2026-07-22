import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide BrandRepository;
import 'package:mycosmetics_server/src/repositories/brand_repository.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

class BrandService {
  final BrandRepository _brands = BrandRepository();

  Future<List<Brand>> listAll(Session session) {
    return _brands.listAll(session);
  }

  Future<Brand> create(
    Session session, {
    required String name,
    required String slug,
    String? logoUrl,
    String? description,
  }) async {
    CatalogValidator.requireNonEmpty(name, 'Brand name');
    CatalogValidator.validateSlug(slug);
    CatalogValidator.validateUrl(logoUrl, 'Brand logo URL');

    final existingSlug = await _brands.findBySlug(session, slug);
    if (existingSlug != null) {
      throw CatalogValidationException('A brand with this slug already exists.');
    }

    final now = DateTime.now().toUtc();
    return _brands.create(
      session,
      Brand(
        name: name.trim(),
        slug: slug,
        logoUrl: logoUrl,
        description: description,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Brand> update(
    Session session, {
    required int id,
    String? name,
    String? logoUrl,
    String? description,
    bool? isActive,
  }) async {
    final existing = await _brands.findById(session, id);
    if (existing == null) throw CatalogValidationException('Brand not found.');
    if (logoUrl != null) CatalogValidator.validateUrl(logoUrl, 'Brand logo URL');

    return _brands.update(
      session,
      existing.copyWith(
        name: name?.trim() ?? existing.name,
        logoUrl: logoUrl ?? existing.logoUrl,
        description: description ?? existing.description,
        isActive: isActive ?? existing.isActive,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> delete(Session session, int id) async {
    final existing = await _brands.findById(session, id);
    if (existing == null) throw CatalogValidationException('Brand not found.');
    if (await _brands.hasProducts(session, id)) {
      throw CatalogValidationException('Cannot delete a brand that has products. Deactivate it instead.');
    }
    await _brands.delete(session, id);
  }
}
