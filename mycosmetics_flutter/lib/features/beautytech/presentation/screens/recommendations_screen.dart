import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../product_details/data/product_details_repository.dart';
import '../../data/beautytech_repository.dart';
import '../providers/beautytech_providers.dart';
import '../widgets/match_score_ring.dart';

const _categoryFilters = <String?>[null, 'foundation', 'concealer', 'blush', 'lipstick', 'eyeshadow'];

/// Recommendation results screen -- calls `recommendation.generate()` and
/// shows cards with the real `ScoreBreakdown.finalScore` match percentage
/// (`pulseRing` motif) and the server's honest `reason` explanation text.
/// Copy uses "matched to your skin tone and undertone", never "AI
/// recommends" (see CLAUDE.md task brief -- the score is real rule-based
/// scoring + usage signals, not a fabricated ML confidence).
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  String? _categoryFilter;
  bool _addingToCartId = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    final error = await ref.read(recommendationControllerProvider.notifier).generate(categoryFilter: _categoryFilter);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _addToCart(ShadeRecommendationDetail detail) async {
    final authed = ref.read(authControllerProvider).value?.hasSession ?? false;
    if (!authed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to continue.')));
      return;
    }
    setState(() => _addingToCartId = true);
    try {
      await ref.read(beautyTechRepositoryProvider).recordEvent(
            recommendationId: detail.recommendation.id!,
            eventType: RecommendationEventType.addedToCart,
          );
      await ref.read(productDetailsRepositoryProvider).addToCart(
            variantId: detail.recommendation.productVariantId,
            quantity: 1,
          );
      // Cart screen re-fetches on next view via its own controller; no
      // shared cache to invalidate here beyond that (see cart_providers.dart).
      ref.invalidate(cartControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't add to cart")));
    } finally {
      if (mounted) setState(() => _addingToCartId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;

    final asyncResult = ref.watch(recommendationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              itemCount: _categoryFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final filter = _categoryFilters[i];
                final selected = filter == _categoryFilter;
                return ChoiceChip(
                  label: Text(filter == null ? 'All' : _capitalize(filter)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _categoryFilter = filter);
                    _generate();
                  },
                  selectedColor: chipText,
                  backgroundColor: chipBg,
                  labelStyle: TextStyle(color: selected ? Colors.white : chipText, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          Expanded(
            child: asyncResult.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Couldn't load recommendations", style: TextStyle(color: muted)),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(onPressed: _generate, child: const Text('Retry')),
                  ],
                ),
              ),
              data: (result) {
                if (result == null || result.recommendations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.face_retouching_natural_outlined, size: 48, color: muted),
                        const SizedBox(height: AppSpacing.sm),
                        Text('No recommendations yet', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Complete your skin tone scan first to get matched shades.',
                          style: TextStyle(color: muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PillButton(
                          label: 'Scan Skin Tone',
                          onPressed: () => context.push(AppRoutes.beautyProfileSetup),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: result.recommendations.length,
                  itemBuilder: (_, i) {
                    final detail = result.recommendations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RecommendationCard(
                        detail: detail,
                        busy: _addingToCartId,
                        onView: () => ref.read(recommendationControllerProvider.notifier).recordViewed(detail.recommendation.id!),
                        onAddToCart: () => _addToCart(detail),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.detail, required this.busy, required this.onView, required this.onAddToCart});

  final ShadeRecommendationDetail detail;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onAddToCart;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _viewed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final detail = widget.detail;
    final score = detail.scoreBreakdown?.finalScore ?? (detail.recommendation.confidenceScore * 100).round();

    return AppCard(
      onTap: () {
        if (!_viewed) {
          _viewed = true;
          widget.onView();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SizedBox(
              width: 64,
              height: 64,
              child: detail.imageUrl != null
                  ? Image.network(
                      detail.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImageFallback(hex: detail.hexColor, muted: muted),
                    )
                  : _ImageFallback(hex: detail.hexColor, muted: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.productName, style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                if (detail.variantName != null && detail.variantName!.isNotEmpty)
                  Text(detail.variantName!, style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: AppSpacing.xs),
                Text(detail.recommendation.reason, style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
                PillButton(
                  label: 'Add to Cart',
                  icon: Icons.add_shopping_cart,
                  onPressed: widget.busy ? null : widget.onAddToCart,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MatchScoreRing(score: score),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.hex, required this.muted});

  final String? hex;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    if (hex != null) {
      final cleaned = hex!.replaceAll('#', '');
      return Container(color: Color(int.parse('FF$cleaned', radix: 16)));
    }
    return Container(color: muted.withValues(alpha: 0.12), child: Icon(Icons.spa_outlined, color: muted));
  }
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
