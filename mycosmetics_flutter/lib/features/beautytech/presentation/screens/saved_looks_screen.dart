import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/beautytech_providers.dart';

/// Saved looks list -- CRUD via `savedLook.*`, favorite toggle, delete
/// confirmation (destructive action per CLAUDE.md admin/customer
/// convention).
class SavedLooksScreen extends ConsumerWidget {
  const SavedLooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final asyncLooks = ref.watch(savedLooksControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Looks')),
      body: asyncLooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load saved looks", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(savedLooksControllerProvider),
                child: Text('Retry', style: TextStyle(color: chipText)),
              ),
            ],
          ),
        ),
        data: (looks) {
          if (looks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No saved looks yet', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.82,
            ),
            itemCount: looks.length,
            itemBuilder: (_, i) {
              final look = looks[i];
              return _SavedLookTile(
                look: look,
                onTap: () => context.push(AppRoutes.beautySavedLookDetail, extra: look),
                onToggleFavorite: () => ref.read(savedLooksControllerProvider.notifier).toggleFavorite(look),
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedLookTile extends StatelessWidget {
  const _SavedLookTile({required this.look, required this.onTap, required this.onToggleFavorite});

  final SavedLook look;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: SizedBox.expand(
                    child: Image.network(
                      look.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: muted.withValues(alpha: 0.12),
                        child: Icon(Icons.spa_outlined, color: muted),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onToggleFavorite,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: Icon(
                        look.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: chipText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            look.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: heading, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
