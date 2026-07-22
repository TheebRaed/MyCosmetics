import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/profile_providers.dart';

/// Wishlist screen -- `/profile/wishlist`. Real via `WishlistEndpoint.list`
/// (already wired for add/remove on PDP -- see product_details_repository.dart),
/// this is the dedicated management screen listing saved products.
///
/// "Add to cart" is NOT a one-tap action here: `WishlistEndpoint.moveToCart`
/// requires a `variantId`, but `WishlistItemDetail` (the list read-model)
/// doesn't carry variant/shade options -- only PDP has that (via
/// `ProductDetail.variants`). Tapping a card opens the product's PDP where
/// a real shade/variant can be picked, rather than guessing a variant here.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final asyncWishlist = ref.watch(wishlistControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: asyncWishlist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your wishlist", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => ref.invalidate(wishlistControllerProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 48, color: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Your wishlist is empty', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tap the heart on any product to save it here.', style: TextStyle(color: muted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => context.push(AppRoutes.productDetails(item.wishlistItem.productId)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: muted.withValues(alpha: 0.12)),
                                )
                              : Container(color: muted.withValues(alpha: 0.12), child: Icon(Icons.spa_outlined, color: muted)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: heading, fontWeight: FontWeight.w600),
                            ),
                            if (!item.isInStock)
                              Text('Out of stock', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                            const SizedBox(height: AppSpacing.xs),
                            Text('\$${item.basePrice.toStringAsFixed(2)}',
                                style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: muted),
                            onPressed: () async {
                              final error = await ref
                                  .read(wishlistControllerProvider.notifier)
                                  .remove(item.wishlistItem.id!);
                              if (!context.mounted || error == null) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            },
                          ),
                          Icon(Icons.chevron_right, color: chipText),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
