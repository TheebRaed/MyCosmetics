import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/home_repository.dart';

part 'home_providers.g.dart';

/// One independent provider per Home section so a slow/failing section
/// (e.g. Best Sellers timing out) never blocks New Arrivals or Categories
/// from rendering -- each gets its own AsyncValue loading/error/data state
/// in the UI.
@riverpod
Future<List<ProductDetail>> newArrivals(Ref ref) async {
  final result = await ref.watch(homeRepositoryProvider).newArrivals();
  return result.items;
}

@riverpod
Future<List<ProductDetail>> bestSellers(Ref ref) async {
  final result = await ref.watch(homeRepositoryProvider).bestSellers();
  return result.items;
}

@riverpod
Future<List<ProductDetail>> featuredProducts(Ref ref) async {
  final result = await ref.watch(homeRepositoryProvider).featured();
  return result.items;
}

@riverpod
Future<List<Category>> topLevelCategories(Ref ref) {
  return ref.watch(homeRepositoryProvider).topLevelCategories();
}

/// Recently viewed is local-only (see [RecentlyViewedStore]) -- fetches
/// full product details for the stored ids via `getDetails`, dropping any
/// id that 404s (deleted/deactivated since it was viewed) rather than
/// surfacing an error for the whole section.
@riverpod
Future<List<ProductDetail>> recentlyViewed(Ref ref) async {
  final store = await ref.watch(recentlyViewedStoreProvider.future);
  final ids = store.getIds();
  if (ids.isEmpty) return const [];

  final repo = ref.watch(homeRepositoryProvider);
  final results = await Future.wait(
    ids.map((id) async {
      try {
        return await repo.productDetails(id);
      } catch (_) {
        return null;
      }
    }),
  );
  return results.whereType<ProductDetail>().toList();
}
