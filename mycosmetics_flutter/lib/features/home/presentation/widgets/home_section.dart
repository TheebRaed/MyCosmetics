import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/product_card.dart';

/// Horizontal product rail with independent loading/empty/error/success
/// states, per CLAUDE.md UI rules -- one slow/failing section (e.g. Best
/// Sellers) never blocks the rest of Home from rendering.
class HomeProductSection extends StatelessWidget {
  const HomeProductSection({
    super.key,
    required this.title,
    required this.asyncProducts,
    required this.onRetry,
    required this.emptyMessage,
    this.onProductTap,
  });

  final String title;
  final AsyncValue<List<ProductDetail>> asyncProducts;
  final VoidCallback onRetry;
  final String emptyMessage;
  final void Function(ProductDetail)? onProductTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 240,
          child: asyncProducts.when(
            loading: () => const _SectionSkeleton(),
            error: (err, __) => _SectionError(onRetry: onRetry),
            data: (items) {
              if (items.isEmpty) return _SectionEmpty(message: emptyMessage);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => ProductCard(
                  product: items[i],
                  onTap: onProductTap == null ? null : () => onProductTap!(items[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatefulWidget {
  const _SectionSkeleton();

  @override
  State<_SectionSkeleton> createState() => _SectionSkeletonState();
}

/// Simple pulsing-opacity skeleton -- the app has no `shimmer` package
/// dependency yet, so this reuses [AppCard] tokens instead of pulling in a
/// new dependency for a first pass.
class _SectionSkeletonState extends State<_SectionSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.35, end: 0.85)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, __) => SizedBox(
          width: 152,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(height: 12, width: 100, color: muted.withValues(alpha: 0.15)),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 12, width: 60, color: muted.withValues(alpha: 0.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load this section", style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: TextStyle(color: chipText, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
