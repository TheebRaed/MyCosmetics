import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Top-level category chip row, backed by `CategoryEndpoint.listTopLevel`.
/// Tapping a chip is a no-op for now -- there's no category/search results
/// screen wired to accept a categoryId yet (that's the Search feature's
/// job, out of scope here); chips are display/browse only on this slice.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.asyncCategories,
    required this.onRetry,
  });

  final AsyncValue<List<Category>> asyncCategories;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return SizedBox(
      height: 44,
      child: asyncCategories.when(
        loading: () => Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: chipText),
          ),
        ),
        error: (err, __) => Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text('Couldn\'t load categories -- Retry', style: TextStyle(color: chipText)),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(child: Text('No categories yet', style: TextStyle(color: muted)));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final category = categories[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  category.name,
                  style: TextStyle(color: chipText, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
