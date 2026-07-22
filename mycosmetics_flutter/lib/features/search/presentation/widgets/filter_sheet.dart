import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../providers/search_providers.dart';

/// Category / Brand / Price / Sort filter sheet. Shade filtering is
/// deliberately omitted -- see search_repository.dart doc comment (shades
/// live on ProductVariant, no backend param exists to filter product search
/// by variant-level shade).
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FilterSheetContent(),
  );
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent();

  @override
  ConsumerState<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final params = ref.read(searchControllerProvider);
    _minController = TextEditingController(text: params.minPrice?.toStringAsFixed(0) ?? '');
    _maxController = TextEditingController(text: params.maxPrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;

    final categories = ref.watch(searchCategoriesProvider);
    final brands = ref.watch(searchBrandsProvider);
    final params = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.drawer(Theme.of(context).brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: heading)),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      _minController.clear();
                      _maxController.clear();
                    },
                    child: Text('Clear all', style: TextStyle(color: chipText)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Sort by', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ProductSortBy.values.map((sort) {
                  final selected = params.sortBy == sort;
                  return ChoiceChip(
                    label: Text(_sortLabel(sort)),
                    selected: selected,
                    onSelected: (_) => controller.setSortBy(sort),
                    selectedColor: chipText,
                    backgroundColor: chipBg,
                    labelStyle: TextStyle(color: selected ? Colors.white : chipText, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Category', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              categories.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => Text("Couldn't load categories", style: TextStyle(color: muted)),
                data: (items) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: items.map((c) {
                    final selected = params.categoryId == c.id;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (sel) => controller.setCategory(sel ? c.id : null),
                      selectedColor: chipText,
                      backgroundColor: chipBg,
                      labelStyle: TextStyle(color: selected ? Colors.white : chipText, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Brand', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              brands.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => Text("Couldn't load brands", style: TextStyle(color: muted)),
                data: (items) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: items.map((b) {
                    final selected = params.brandId == b.id;
                    return ChoiceChip(
                      label: Text(b.name),
                      selected: selected,
                      onSelected: (sel) => controller.setBrand(sel ? b.id : null),
                      selectedColor: chipText,
                      backgroundColor: chipBg,
                      labelStyle: TextStyle(color: selected ? Colors.white : chipText, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Price range', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Min'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: 'Apply filters',
                expand: true,
                onPressed: () {
                  controller.setPriceRange(
                    double.tryParse(_minController.text.trim()),
                    double.tryParse(_maxController.text.trim()),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(ProductSortBy sort) {
    switch (sort) {
      case ProductSortBy.newest:
        return 'Newest';
      case ProductSortBy.priceLowToHigh:
        return 'Price: Low to High';
      case ProductSortBy.priceHighToLow:
        return 'Price: High to Low';
      case ProductSortBy.ratingHighToLow:
        return 'Top Rated';
      case ProductSortBy.bestSelling:
        return 'Best Selling';
    }
  }
}
