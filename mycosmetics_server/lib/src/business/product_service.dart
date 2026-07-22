import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide CategoryRepository, BrandRepository, ProductRepository, ProductVariantRepository, ProductImageRepository;
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_image_repository.dart';
import 'package:mycosmetics_server/src/repositories/category_repository.dart';
import 'package:mycosmetics_server/src/repositories/brand_repository.dart';
import 'package:mycosmetics_server/src/utils/catalog_validator.dart';

class ProductService {
  final ProductRepository _products = ProductRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();
  final ProductImageRepository _images = ProductImageRepository();
  final CategoryRepository _categories = CategoryRepository();
  final BrandRepository _brands = BrandRepository();

  Future<ProductDetail> _composeDetail(Session session, Product product) async {
    final variants = await _variants.listForProduct(session, product.id!);
    final images = await _images.listForProduct(session, product.id!);
    final category = await _categories.findById(session, product.categoryId);
    final brand = await _brands.findById(session, product.brandId);
    return ProductDetail(
      product: product,
      variants: variants,
      images: images,
      brandName: brand?.name ?? 'Unknown brand',
      categoryName: category?.name ?? 'Unknown category',
    );
  }

  Future<ProductDetail> getDetails(Session session, int id) async {
    final product = await _products.findById(session, id);
    if (product == null) throw CatalogValidationException('Product not found.');
    return _composeDetail(session, product);
  }

  Future<ProductDetail> getDetailsBySlug(Session session, String slug) async {
    final product = await _products.findBySlug(session, slug);
    if (product == null) throw CatalogValidationException('Product not found.');
    return _composeDetail(session, product);
  }

  Future<ProductListResult> list(
    Session session, {
    ProductFilter filter = const ProductFilter(),
    ProductSortBy sortBy = ProductSortBy.newest,
    int page = 0,
    int pageSize = 20,
  }) async {
    CatalogValidator.validatePagination(page, pageSize);
    if (filter.minPrice != null) CatalogValidator.validatePrice(filter.minPrice!, fieldName: 'minPrice');
    if (filter.maxPrice != null) CatalogValidator.validatePrice(filter.maxPrice!, fieldName: 'maxPrice');
    if (filter.minPrice != null && filter.maxPrice != null && filter.minPrice! > filter.maxPrice!) {
      throw CatalogValidationException('minPrice cannot be greater than maxPrice.');
    }

    final totalCount = await _products.count(session, filter);
    final products = await _products.list(session, filter, sortBy: sortBy, page: page, pageSize: pageSize);

    // Compose details concurrently rather than sequentially — for a 20-item
    // page this is the difference between ~20 sequential round-trip batches
    // and 20 batches running in parallel.
    final details = await Future.wait(products.map((p) => _composeDetail(session, p)));

    return ProductListResult(items: details, totalCount: totalCount, page: page, pageSize: pageSize);
  }

  Future<Product> create(
    Session session, {
    required int categoryId,
    required int brandId,
    required String name,
    required String slug,
    required String description,
    required double basePrice,
    bool isFeatured = false,
    bool isBestSeller = false,
    bool isNewArrival = false,
  }) async {
    CatalogValidator.requireNonEmpty(name, 'Product name');
    CatalogValidator.requireNonEmpty(description, 'Product description');
    CatalogValidator.validateSlug(slug);
    CatalogValidator.validatePrice(basePrice);

    final category = await _categories.findById(session, categoryId);
    if (category == null) throw CatalogValidationException('Category not found.');
    final brand = await _brands.findById(session, brandId);
    if (brand == null) throw CatalogValidationException('Brand not found.');

    if (await _products.slugExists(session, slug)) {
      throw CatalogValidationException('A product with this slug already exists.');
    }

    final now = DateTime.now().toUtc();
    return _products.create(
      session,
      Product(
        categoryId: categoryId,
        brandId: brandId,
        name: name.trim(),
        slug: slug,
        description: description,
        basePrice: basePrice,
        ratingAvg: 0,
        ratingCount: 0,
        isFeatured: isFeatured,
        isBestSeller: isBestSeller,
        isNewArrival: isNewArrival,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Product> update(
    Session session, {
    required int id,
    String? name,
    String? description,
    int? categoryId,
    int? brandId,
    double? basePrice,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
    bool? isActive,
  }) async {
    final existing = await _products.findById(session, id, includeInactive: true);
    if (existing == null) throw CatalogValidationException('Product not found.');

    if (categoryId != null) {
      final category = await _categories.findById(session, categoryId);
      if (category == null) throw CatalogValidationException('Category not found.');
    }
    if (brandId != null) {
      final brand = await _brands.findById(session, brandId);
      if (brand == null) throw CatalogValidationException('Brand not found.');
    }
    if (basePrice != null) CatalogValidator.validatePrice(basePrice);

    return _products.update(
      session,
      existing.copyWith(
        name: name?.trim() ?? existing.name,
        description: description ?? existing.description,
        categoryId: categoryId ?? existing.categoryId,
        brandId: brandId ?? existing.brandId,
        basePrice: basePrice ?? existing.basePrice,
        isFeatured: isFeatured ?? existing.isFeatured,
        isBestSeller: isBestSeller ?? existing.isBestSeller,
        isNewArrival: isNewArrival ?? existing.isNewArrival,
        isActive: isActive ?? existing.isActive,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Soft-delete only. Hard-deleting a product would cascade through
  /// variants/images (schema allows it) but would also orphan any future
  /// order_items/reviews/cart_items referencing it once those modules land
  /// in Phase 3 — soft-delete keeps that referential history intact.
  Future<void> delete(Session session, int id) async {
    final existing = await _products.findById(session, id, includeInactive: true);
    if (existing == null) throw CatalogValidationException('Product not found.');
    await _products.softDelete(session, id);
  }

  /// Recomputes Product.basePrice from the cheapest active variant.
  /// Called by ProductVariantService after create/update/delete so the
  /// denormalized list-view price never drifts from the source of truth.
  Future<void> syncBasePriceFromVariants(Session session, int productId) async {
    final minPrice = await _variants.minActivePrice(session, productId);
    if (minPrice == null) return;
    final product = await _products.findById(session, productId, includeInactive: true);
    if (product == null) return;
    await _products.update(session, product.copyWith(basePrice: minPrice, updatedAt: DateTime.now().toUtc()));
  }
}
