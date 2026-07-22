import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../data/search_repository.dart';
import '../providers/search_providers.dart';
import '../widgets/filter_sheet.dart';

/// Customer app Search tab.
///
/// Built against real backend data:
/// - Text search + live "suggestions" (results refresh as you type,
///   debounced) via `ProductEndpoint.search(searchQuery: ...)`
/// - Category / Brand / Price filters + Sort, all real `search` params
/// - Pagination (page/pageSize on `search`)
/// - Search history -- local SharedPreferences only, recorded when a search
///   actually runs (same pattern as Home's RecentlyViewedStore)
///
/// Deliberately omitted (see search_repository.dart for detail):
/// - Voice Search -- needs a mic/speech-to-text package (e.g.
///   `speech_to_text`) not currently a dependency. Not pulled in silently;
///   flagged as a follow-up dependency decision.
/// - Shade filter -- shades live on ProductVariant, `ProductFilter` has no
///   variant-level filter param today.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchControllerProvider.notifier).setQuery(value);
    });
  }

  Future<void> _recordHistoryIfSubmitted(String value) async {
    if (value.trim().isEmpty) return;
    final store = await ref.read(searchHistoryStoreProvider.future);
    await store.record(value.trim());
    ref.invalidate(searchHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final inputBg = isDark ? AppColorsDark.inputBg : AppColorsLight.inputBg;

    final params = ref.watch(searchControllerProvider);
    final results = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);
    final showHistory = _textController.text.trim().isEmpty && !params.hasActiveFilters;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: TextField(
                        controller: _textController,
                        onChanged: (v) {
                          setState(() {});
                          _onChanged(v);
                        },
                        onSubmitted: _recordHistoryIfSubmitted,
                        style: TextStyle(color: heading),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                          prefixIcon: Icon(Icons.search, color: muted),
                          suffixIcon: _textController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close, color: muted),
                                  onPressed: () {
                                    _textController.clear();
                                    ref.read(searchControllerProvider.notifier).setQuery('');
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => showFilterSheet(context),
                        icon: Icon(Icons.tune, color: chipText),
                        style: IconButton.styleFrom(backgroundColor: inputBg),
                      ),
                      if (params.hasActiveFilters)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: chipText, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: showHistory
                  ? _SearchHistoryView(
                      asyncHistory: history,
                      onRetry: () => ref.invalidate(searchHistoryProvider),
                      onTapTerm: (term) {
                        _textController.text = term;
                        ref.read(searchControllerProvider.notifier).setQuery(term);
                        setState(() {});
                      },
                      onClear: () async {
                        final store = await ref.read(searchHistoryStoreProvider.future);
                        await store.clear();
                        ref.invalidate(searchHistoryProvider);
                      },
                    )
                  : _SearchResultsView(
                      asyncResults: results,
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHistoryView extends StatelessWidget {
  const _SearchHistoryView({
    required this.asyncHistory,
    required this.onRetry,
    required this.onTapTerm,
    required this.onClear,
  });

  final AsyncValue<List<String>> asyncHistory;
  final VoidCallback onRetry;
  final void Function(String) onTapTerm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return asyncHistory.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
      data: (terms) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
        final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

        if (terms.isEmpty) {
          return Center(
            child: Text('Search for products, brands, or categories', style: TextStyle(color: muted)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(onPressed: onClear, child: Text('Clear', style: TextStyle(color: chipText))),
                ],
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: terms
                    .map((t) => ActionChip(
                          label: Text(t),
                          onPressed: () => onTapTerm(t),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({required this.asyncResults, required this.onRetry});

  final AsyncValue<ProductListResult> asyncResults;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return asyncResults.when(
      loading: () => const _ResultsSkeleton(),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load results", style: TextStyle(color: muted)),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onRetry, child: Text('Retry', style: TextStyle(color: chipText))),
          ],
        ),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return Center(child: Text('No products found', style: TextStyle(color: muted)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.62,
          ),
          itemCount: result.items.length,
          itemBuilder: (_, i) {
            final product = result.items[i];
            return ProductCard(
              product: product,
              width: double.infinity,
              onTap: () => context.push(AppRoutes.productDetails(product.product.id!)),
            );
          },
        );
      },
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => AppCard(
        child: DecoratedBox(decoration: BoxDecoration(color: muted.withValues(alpha: 0.12))),
      ),
    );
  }
}
