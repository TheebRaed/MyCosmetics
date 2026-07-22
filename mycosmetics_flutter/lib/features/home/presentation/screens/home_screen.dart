import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../providers/home_providers.dart';
import '../widgets/category_chips.dart';
import '../widgets/home_section.dart';

/// Customer app Home tab.
///
/// Sections built against real backend data:
/// - Categories (`CategoryEndpoint.listTopLevel`)
/// - New Arrivals (`ProductEndpoint.search(isNewArrival: true)`)
/// - Best Sellers (`ProductEndpoint.search(isBestSeller: true)`)
/// - Featured Products (`ProductEndpoint.search(isFeatured: true)` --
///   stands in for both "Featured Collections" and "Recommended Products"
///   from the spec; neither a Collection model nor a personalized
///   recommender exists on the backend yet)
/// - Recently Viewed (local SharedPreferences tracking, see
///   home_repository.dart -- empty until a product detail screen exists to
///   call `RecentlyViewedStore.recordView`)
///
/// Deliberately omitted (see home_repository.dart doc comment for why):
/// Trending, Special Offers (dedicated query), AI Recommendations,
/// Continue Shopping (folded into Recently Viewed rather than duplicated).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newArrivals = ref.watch(newArrivalsProvider);
    final bestSellers = ref.watch(bestSellersProvider);
    final featured = ref.watch(featuredProductsProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);
    final categories = ref.watch(topLevelCategoriesProvider);

    Future<void> refreshAll() async {
      ref.invalidate(newArrivalsProvider);
      ref.invalidate(bestSellersProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(recentlyViewedProvider);
      ref.invalidate(topLevelCategoriesProvider);
      await Future.wait([
        ref.read(newArrivalsProvider.future),
        ref.read(bestSellersProvider.future),
        ref.read(featuredProductsProvider.future),
        ref.read(recentlyViewedProvider.future),
        ref.read(topLevelCategoriesProvider.future),
      ]);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'My Cosmetics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: heading),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryChips(
                asyncCategories: categories,
                onRetry: () => ref.invalidate(topLevelCategoriesProvider),
              ),
              const SizedBox(height: AppSpacing.lg),
              HomeProductSection(
                title: 'New Arrivals',
                asyncProducts: newArrivals,
                onRetry: () => ref.invalidate(newArrivalsProvider),
                emptyMessage: 'No new arrivals yet -- check back soon.',
                onProductTap: (p) => context.push(AppRoutes.productDetails(p.product.id!)),
              ),
              const SizedBox(height: AppSpacing.lg),
              HomeProductSection(
                title: 'Best Sellers',
                asyncProducts: bestSellers,
                onRetry: () => ref.invalidate(bestSellersProvider),
                emptyMessage: 'No best sellers yet.',
                onProductTap: (p) => context.push(AppRoutes.productDetails(p.product.id!)),
              ),
              const SizedBox(height: AppSpacing.lg),
              HomeProductSection(
                title: 'Featured',
                asyncProducts: featured,
                onRetry: () => ref.invalidate(featuredProductsProvider),
                emptyMessage: 'No featured products yet.',
                onProductTap: (p) => context.push(AppRoutes.productDetails(p.product.id!)),
              ),
              const SizedBox(height: AppSpacing.lg),
              HomeProductSection(
                title: 'Recently Viewed',
                asyncProducts: recentlyViewed,
                onRetry: () => ref.invalidate(recentlyViewedProvider),
                emptyMessage: 'Products you view will show up here.',
                onProductTap: (p) => context.push(AppRoutes.productDetails(p.product.id!)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
