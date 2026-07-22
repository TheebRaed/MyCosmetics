import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/product_details_repository.dart';
import '../providers/product_details_providers.dart';

/// Customer app Product Details screen (PDP), reached via `/product/:id`
/// from Home/Search product taps.
///
/// Built against real backend data:
/// - Gallery / multiple images (`ProductDetail.images`)
/// - Variant/shade/size selector + stock status (`ProductDetail.variants`,
///   `stockQty`/`isActive`)
/// - Ratings summary (`Product.ratingAvg`/`ratingCount`, denormalized)
/// - Reviews list, read-only (`ReviewEndpoint.listForProduct`)
/// - Similar products -- same-category real query, not AI-personalized
///   (`ProductEndpoint.search(categoryId: ...)`)
/// - Wishlist add/remove (`WishlistEndpoint`)
/// - Add to Cart with selected variant (`CartEndpoint.addItem`)
///
/// Deliberately omitted (see product_details_repository.dart for why):
/// - Product videos -- no video URL field on the model.
/// - Writing a review -- read-only for this slice; write flow (requires an
///   eligible orderItemId) is separate future work.
/// - AI Match %, Virtual Try-On, "Complete The Look", AI-driven
///   "Recommended Products" -- no recommendation-engine endpoint exists.
/// - Buy Now, Coupons, Delivery Information -- checkout doesn't exist yet /
///   no delivery-estimate data source; omitted rather than faked.
/// - Share Product -- would need a new `share_plus` dependency, not pulled
///   in for this pass.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int? _selectedVariantId;
  bool _addingToCart = false;
  bool _togglingWishlist = false;

  void _showSignInPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to continue.')),
    );
  }

  Future<void> _addToCart(ProductVariant variant) async {
    final authed = ref.read(authControllerProvider).value?.hasSession ?? false;
    if (!authed) return _showSignInPrompt();

    setState(() => _addingToCart = true);
    try {
      await ref.read(productDetailsRepositoryProvider).addToCart(variantId: variant.id!, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't add to cart")));
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _toggleWishlist(int productId, List<WishlistItemDetail> current) async {
    final authed = ref.read(authControllerProvider).value?.hasSession ?? false;
    if (!authed) return _showSignInPrompt();

    final matches = current.where((w) => w.wishlistItem.productId == productId);
    final existing = matches.isEmpty ? null : matches.first;
    setState(() => _togglingWishlist = true);
    try {
      final repo = ref.read(productDetailsRepositoryProvider);
      if (existing != null) {
        await repo.removeFromWishlist(existing.wishlistItem.id!);
      } else {
        await repo.addToWishlist(productId);
      }
      ref.invalidate(wishlistProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't update wishlist")));
    } finally {
      if (mounted) setState(() => _togglingWishlist = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(productDetailProvider(widget.productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return Scaffold(
      body: SafeArea(
        child: asyncDetail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't load this product", style: TextStyle(color: muted)),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(productDetailProvider(widget.productId)),
                  child: Text('Retry', style: TextStyle(color: chipText)),
                ),
              ],
            ),
          ),
          data: (detail) {
            final variants = detail.variants;
            _selectedVariantId ??= variants.firstWhere(
                  (v) => v.isActive && v.stockQty > 0,
                  orElse: () => variants.isNotEmpty ? variants.first : ProductVariant(
                        productId: detail.product.id!,
                        sku: '',
                        price: detail.product.basePrice,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                ).id;
            final selectedMatches = variants.where((v) => v.id == _selectedVariantId);
            final selectedVariant = selectedMatches.isEmpty ? null : selectedMatches.first;
            final inStock = selectedVariant != null && selectedVariant.isActive && selectedVariant.stockQty > 0;

            final wishlistAsync = ref.watch(wishlistProvider);
            final isWishlisted = wishlistAsync.value?.any((w) => w.wishlistItem.productId == detail.product.id) ?? false;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 110),
                  children: [
                    Stack(
                      children: [
                        _Gallery(images: detail.images),
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: _CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => context.pop(),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: _CircleIconButton(
                            icon: isWishlisted ? Icons.favorite : Icons.favorite_border,
                            iconColor: isWishlisted ? chipText : null,
                            loading: _togglingWishlist,
                            onTap: () => _toggleWishlist(detail.product.id!, wishlistAsync.value ?? const []),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(detail.brandName, style: TextStyle(color: muted)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            detail.product.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: heading),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Text(
                                '\$${(selectedVariant?.price ?? detail.product.basePrice).toStringAsFixed(2)}',
                                style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 22),
                              ),
                              if (detail.product.ratingCount > 0) ...[
                                const SizedBox(width: AppSpacing.md),
                                Icon(Icons.star_rounded, size: 18, color: chipText),
                                const SizedBox(width: 2),
                                Text('${detail.product.ratingAvg.toStringAsFixed(1)} (${detail.product.ratingCount})',
                                    style: TextStyle(color: muted)),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _StockBadge(inStock: inStock),
                          const SizedBox(height: AppSpacing.lg),
                          if (variants.length > 1) ...[
                            Text('Shade / Size', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppSpacing.sm),
                            _VariantSelector(
                              variants: variants,
                              selectedId: _selectedVariantId,
                              onSelected: (id) => setState(() => _selectedVariantId = id),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          Text('Description', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(detail.product.description, style: TextStyle(color: heading)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReviewsSection(productId: detail.product.id!),
                    const SizedBox(height: AppSpacing.lg),
                    _SimilarProductsSection(
                      categoryId: detail.product.categoryId,
                      excludeProductId: detail.product.id!,
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _AddToCartBar(
                    inStock: inStock,
                    loading: _addingToCart,
                    onAddToCart: selectedVariant == null ? null : () => _addToCart(selectedVariant),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<ProductImage> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: muted.withValues(alpha: 0.12),
          child: Icon(Icons.spa_outlined, size: 48, color: muted),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Image.network(
              widget.images[i].url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: muted.withValues(alpha: 0.12),
                child: Icon(Icons.spa_outlined, size: 48, color: muted),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? muted : muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.circle),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap, this.iconColor, this.loading = false});

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, color: iconColor ?? Colors.black87),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? Colors.green.shade700 : Colors.red.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(inStock ? Icons.check_circle : Icons.cancel, size: 16, color: color),
        const SizedBox(width: 4),
        Text(inStock ? 'In stock' : 'Out of stock', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({required this.variants, required this.selectedId, required this.onSelected});

  final List<ProductVariant> variants;
  final int? selectedId;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: variants.map((v) {
        final selected = v.id == selectedId;
        final available = v.isActive && v.stockQty > 0;
        final label = [v.shadeName, v.size].where((s) => s != null && s.isNotEmpty).join(' / ');
        return ChoiceChip(
          label: Text(label.isEmpty ? v.sku : label),
          selected: selected,
          onSelected: available ? (_) => onSelected(v.id!) : null,
          selectedColor: chipText,
          backgroundColor: available ? chipBg : chipBg.withValues(alpha: 0.4),
          labelStyle: TextStyle(
            color: selected ? Colors.white : (available ? chipText : muted),
            fontWeight: FontWeight.w600,
            decoration: available ? null : TextDecoration.lineThrough,
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(productReviewsProvider(productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: heading)),
          const SizedBox(height: AppSpacing.sm),
          asyncReviews.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Row(
              children: [
                Text("Couldn't load reviews", style: TextStyle(color: muted)),
                TextButton(
                  onPressed: () => ref.invalidate(productReviewsProvider(productId)),
                  child: Text('Retry', style: TextStyle(color: chipText)),
                ),
              ],
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return Text('No reviews yet.', style: TextStyle(color: muted));
              }
              return Column(
                children: reviews
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 16,
                                      color: chipText,
                                    ),
                                  ),
                                ),
                                if (r.comment != null && r.comment!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(r.comment!, style: TextStyle(color: heading)),
                                ],
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SimilarProductsSection extends ConsumerWidget {
  const _SimilarProductsSection({required this.categoryId, required this.excludeProductId});

  final int categoryId;
  final int excludeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSimilar = ref.watch(
      similarProductsProvider(categoryId: categoryId, excludeProductId: excludeProductId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('Similar Products', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: heading)),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 240,
          child: asyncSimilar.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text("Couldn't load similar products", style: TextStyle(color: muted))),
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Text('No similar products found.', style: TextStyle(color: muted)));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => ProductCard(
                  product: items[i],
                  onTap: () => context.push(AppRoutes.productDetails(items[i].product.id!)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({required this.inStock, required this.loading, required this.onAddToCart});

  final bool inStock;
  final bool loading;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.drawer(brightness),
        boxShadow: AppShadows.elevated(brightness),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: PillButton(
            label: loading ? 'Adding...' : (inStock ? 'Add to Cart' : 'Out of Stock'),
            icon: Icons.shopping_bag_outlined,
            expand: true,
            onPressed: (!inStock || loading) ? null : onAddToCart,
          ),
        ),
      ),
    );
  }
}
