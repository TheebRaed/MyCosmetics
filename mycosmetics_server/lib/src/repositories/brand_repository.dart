import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ProductFilter {
  final int? categoryId;
  final int? brandId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isFeatured;
  final bool? isBestSeller;
  final bool? isNewArrival;
  final String? searchQuery;

  const ProductFilter({
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.isFeatured,
    this.isBestSeller,
    this.isNewArrival,
    this.searchQuery,
  });
}

class ProductRepository {
  Future<Product?> findById(Session session, int id, {bool includeInactive = false}) async {
    final product = await Product.db.findById(session, id);
    if (product == null || product.deletedAt != null) return null;
    if (!includeInactive && !product.isActive) return null;
    return product;
  }

  Future<Product?> findBySlug(Session session, String slug) {
    return Product.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug) & t.deletedAt.equals(null),
    );
  }

  /// Builds the combined where-clause for filter+search, shared by both the
  /// count query and the page query so they never drift out of sync.
  Expression _buildWhere(ProductTable t, ProductFilter filter) {
    Expression where = t.deletedAt.equals(null) & t.isActive.equals(true);
    if (filter.categoryId != null) where = where & t.categoryId.equals(filter.categoryId);
    if (filter.brandId != null) where = where & t.brandId.equals(filter.brandId);
    if (filter.minPrice != null) where = where & t.basePrice.between(filter.minPrice!, double.infinity);
    if (filter.maxPrice != null) where = where & t.basePrice.between(0, filter.maxPrice!);
    if (filter.minRating != null) where = where & t.ratingAvg.between(filter.minRating!, 5);
    if (filter.isFeatured != null) where = where & t.isFeatured.equals(filter.isFeatured);
    if (filter.isBestSeller != null) where = where & t.isBestSeller.equals(filter.isBestSeller);
    if (filter.isNewArrival != null) where = where & t.isNewArrival.equals(filter.isNewArrival);
    return where;
  }

  Future<int> count(Session session, ProductFilter filter) async {
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      return _searchCount(session, filter);
    }
    return Product.db.count(session, where: (t) => _buildWhere(t, filter));
  }

  Future<List<Product>> list(
    Session session,
    ProductFilter filter, {
    required ProductSortBy sortBy,
    required int page,
    required int pageSize,
  }) async {
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      return _search(session, filter, sortBy: sortBy, page: page, pageSize: pageSize);
    }

    return Product.db.find(
      session,
      where: (t) => _buildWhere(t, filter),
      orderBy: _orderByFor(sortBy),
      orderDescending: _isDescendingFor(sortBy),
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  Column Function(ProductTable) _orderByFor(ProductSortBy sortBy) {
    switch (sortBy) {
      case ProductSortBy.priceLowToHigh:
      case ProductSortBy.priceHighToLow:
        return (t) => t.basePrice;
      case ProductSortBy.ratingHighToLow:
        return (t) => t.ratingAvg;
      case ProductSortBy.bestSelling:
        return (t) => t.ratingCount;
      case ProductSortBy.newest:
        return (t) => t.createdAt;
    }
  }

  bool _isDescendingFor(ProductSortBy sortBy) {
    // Only priceLowToHigh sorts ascending; every other option is "biggest/newest first".
    return sortBy != ProductSortBy.priceLowToHigh;
  }

  /// Raw SQL path for full-text search using the generated tsvector column
  /// (see migration 00000000000001). Serverpod's query builder doesn't
  /// expose full-text operators directly, so this drops to unsafeQuery
  /// with bound parameters (never string-interpolated) to stay injection-safe.
  Future<List<Product>> _search(
    Session session,
    ProductFilter filter, {
    required ProductSortBy sortBy,
    required int page,
    required int pageSize,
  }) async {
    final conditions = <String>['"deletedAt" IS NULL', '"isActive" = true', '"searchVector" @@ to_tsquery(\'english\', @query)'];
    final substitutionValues = <String, dynamic>{'query': _toTsQuery(filter.searchQuery!)};

    if (filter.categoryId != null) {
      conditions.add('"categoryId" = @categoryId');
      substitutionValues['categoryId'] = filter.categoryId;
    }
    if (filter.brandId != null) {
      conditions.add('"brandId" = @brandId');
      substitutionValues['brandId'] = filter.brandId;
    }
    if (filter.minPrice != null) {
      conditions.add('"basePrice" >= @minPrice');
      substitutionValues['minPrice'] = filter.minPrice;
    }
    if (filter.maxPrice != null) {
      conditions.add('"basePrice" <= @maxPrice');
      substitutionValues['maxPrice'] = filter.maxPrice;
    }
    if (filter.minRating != null) {
      conditions.add('"ratingAvg" >= @minRating');
      substitutionValues['minRating'] = filter.minRating;
    }

    final orderColumn = _orderColumnNameFor(sortBy);
    final direction = _isDescendingFor(sortBy) ? 'DESC' : 'ASC';

    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "products" WHERE ${conditions.join(' AND ')} '
      'ORDER BY $orderColumn $direction LIMIT @limit OFFSET @offset',
      parameters: QueryParameters.named({
        ...substitutionValues,
        'limit': pageSize,
        'offset': page * pageSize,
      }),
    );
    return rows.map((row) => Product.fromJson(row.toColumnMap())).toList();
  }

  Future<int> _searchCount(Session session, ProductFilter filter) async {
    final conditions = <String>['"deletedAt" IS NULL', '"isActive" = true', '"searchVector" @@ to_tsquery(\'english\', @query)'];
    final substitutionValues = <String, dynamic>{'query': _toTsQuery(filter.searchQuery!)};

    if (filter.categoryId != null) {
      conditions.add('"categoryId" = @categoryId');
      substitutionValues['categoryId'] = filter.categoryId;
    }
    if (filter.brandId != null) {
      conditions.add('"brandId" = @brandId');
      substitutionValues['brandId'] = filter.brandId;
    }
    if (filter.minPrice != null) {
      conditions.add('"basePrice" >= @minPrice');
      substitutionValues['minPrice'] = filter.minPrice;
    }
    if (filter.maxPrice != null) {
      conditions.add('"basePrice" <= @maxPrice');
      substitutionValues['maxPrice'] = filter.maxPrice;
    }
    if (filter.minRating != null) {
      conditions.add('"ratingAvg" >= @minRating');
      substitutionValues['minRating'] = filter.minRating;
    }

    final result = await session.db.unsafeQuery(
      'SELECT COUNT(*) as cnt FROM "products" WHERE ${conditions.join(' AND ')}',
      parameters: QueryParameters.named(substitutionValues),
    );
    return result.first.toColumnMap()['cnt'] as int;
  }

  String _orderColumnNameFor(ProductSortBy sortBy) {
    switch (sortBy) {
      case ProductSortBy.priceLowToHigh:
      case ProductSortBy.priceHighToLow:
        return '"basePrice"';
      case ProductSortBy.ratingHighToLow:
        return '"ratingAvg"';
      case ProductSortBy.bestSelling:
        return '"ratingCount"';
      case ProductSortBy.newest:
        return '"createdAt"';
    }
  }

  /// Sanitizes free-text input into a safe to_tsquery expression: strips
  /// tsquery special characters, splits on whitespace, joins with AND (&).
  /// This prevents the user's search string from being interpreted as
  /// tsquery syntax (which could otherwise throw or behave unexpectedly),
  /// while parameters remain bound (never interpolated into the SQL itself).
  String _toTsQuery(String raw) {
    final cleaned = raw.replaceAll(RegExp(r"[&|!():'\\]"), ' ');
    final terms = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (terms.isEmpty) return '';
    return terms.map((t) => '$t:*').join(' & ');
  }

  Future<Product> create(Session session, Product product) {
    return Product.db.insertRow(session, product);
  }

  Future<Product> update(Session session, Product product) {
    return Product.db.updateRow(session, product);
  }

  Future<void> softDelete(Session session, int id) async {
    final product = await Product.db.findById(session, id);
    if (product == null) return;
    await Product.db.updateRow(
      session,
      product.copyWith(deletedAt: DateTime.now().toUtc(), isActive: false),
    );
  }

  Future<bool> slugExists(Session session, String slug, {int? excludingId}) async {
    final existing = await findBySlug(session, slug);
    if (existing == null) return false;
    if (excludingId != null && existing.id == excludingId) return false;
    return true;
  }
}
