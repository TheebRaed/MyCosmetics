import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/product_service.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart' show ProductFilter;
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class ProductEndpoint extends Endpoint {
  final ProductService _products = ProductService();

  Future<ProductDetail> getDetails(Session session, {required int id}) {
    return _products.getDetails(session, id);
  }

  Future<ProductDetail> getDetailsBySlug(Session session, {required String slug}) {
    return _products.getDetailsBySlug(session, slug);
  }

  /// Single endpoint backs Search, Filter, and Sort from the spec — they're
  /// not separate features at the data layer, just different combinations
  /// of the same filter+sort+paginate query. searchQuery present = Search;
  /// any of category/brand/price/rating present = Filter; sortBy = Sort.
  Future<ProductListResult> search(
    Session session, {
    String? searchQuery,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
    ProductSortBy sortBy = ProductSortBy.newest,
    int page = 0,
    int pageSize = 20,
  }) {
    return _products.list(
      session,
      filter: ProductFilter(
        categoryId: categoryId,
        brandId: brandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        isFeatured: isFeatured,
        isBestSeller: isBestSeller,
        isNewArrival: isNewArrival,
        searchQuery: searchQuery,
      ),
      sortBy: sortBy,
      page: page,
      pageSize: pageSize,
    );
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
    await AuthGuard.requireAdminOrStaff(session);
    return _products.create(
      session,
      categoryId: categoryId,
      brandId: brandId,
      name: name,
      slug: slug,
      description: description,
      basePrice: basePrice,
      isFeatured: isFeatured,
      isBestSeller: isBestSeller,
      isNewArrival: isNewArrival,
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
    await AuthGuard.requireAdminOrStaff(session);
    return _products.update(
      session,
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      brandId: brandId,
      basePrice: basePrice,
      isFeatured: isFeatured,
      isBestSeller: isBestSeller,
      isNewArrival: isNewArrival,
      isActive: isActive,
    );
  }

  Future<void> delete(Session session, {required int id}) async {
    await AuthGuard.requireAdminOrStaff(session);
    await _products.delete(session, id);
  }
}
