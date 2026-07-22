import 'package:flutter/material.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';

/// Compact product tile for horizontal rails (Home sections) and future
/// grids (search/category results, PDP "you may also like"). Deliberately
/// minimal -- no add-to-cart/wishlist actions here, those land with the
/// screens that need them (cart, PDP) rather than being speculatively
/// built into this shared widget now.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.width = 152});

  final ProductDetail product;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final imageUrl = product.images.isNotEmpty ? product.images.first.url : null;
    final discount = product.product.discountPercent;
    final hasDiscount = discount != null && discount > 0;

    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ImagePlaceholder(muted: muted),
                          )
                        : _ImagePlaceholder(muted: muted),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipText,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        '-${discount.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              product.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: heading, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '\$${product.product.basePrice.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (product.product.ratingCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.star_rounded, size: 14, color: chipText),
                  Text(
                    product.product.ratingAvg.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: muted.withValues(alpha: 0.12),
      child: Icon(Icons.spa_outlined, color: muted),
    );
  }
}
