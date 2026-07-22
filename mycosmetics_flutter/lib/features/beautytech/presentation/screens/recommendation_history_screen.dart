import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/beautytech_providers.dart';

/// Lists past `recommendation.generate()` sessions from
/// `recommendation.history()`.
class RecommendationHistoryScreen extends ConsumerWidget {
  const RecommendationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final asyncHistory = ref.watch(recommendationHistoryProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendation History')),
      body: asyncHistory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load history", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(recommendationHistoryProvider()),
                child: Text('Retry', style: TextStyle(color: chipText)),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('No recommendation sessions yet.', style: TextStyle(color: muted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final entry = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.face_retouching_natural, color: chipText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.totalGenerated} shade${entry.totalGenerated == 1 ? '' : 's'} recommended'
                              '${entry.categoryFilter != null ? ' · ${entry.categoryFilter}' : ''}',
                              style: TextStyle(color: heading, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatDate(entry.createdAt),
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
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

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
