import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../home/data/home_repository.dart' show recentlyViewedStoreProvider;
import '../../data/product_details_repository.dart';

part 'product_details_providers.g.dart';

@riverpod
Future<ProductDetail> productDetail(Ref ref, int productId) async {
  final detail = await ref.watch(productDetailsRepositoryProvider).details(productId);
  // Record the view for Home's "Recently Viewed" section (see
  // home_repository.dart -- this is the call site that section was waiting
  // on).
  final store = await ref.watch(recentlyViewedStoreProvider.future);
  await store.recordView(productId);
  return detail;
}

@riverpod
Future<List<ProductDetail>> similarProducts(Ref ref, {required int categoryId, required int excludeProductId}) {
  return ref.watch(productDetailsRepositoryProvider).similarInCategory(
        categoryId: categoryId,
        excludeProductId: excludeProductId,
      );
}

@riverpod
Future<List<Review>> productReviews(Ref ref, int productId) {
  return ref.watch(productDetailsRepositoryProvider).reviews(productId);
}

/// Full wishlist, watched to answer "is this product wishlisted" and find
/// the wishlistItemId needed to remove it -- `WishlistEndpoint` has no
/// single-product lookup, only `list`/`add`/`remove`.
@riverpod
Future<List<WishlistItemDetail>> wishlist(Ref ref) => ref.watch(productDetailsRepositoryProvider).wishlist();
