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
import '../providers/beautytech_providers.dart';

/// Customer app BeautyTech tab home -- the "Beauty" bottom-nav tab.
///
/// Shows skin profile status (set up vs not set up) + quick actions:
/// scan/update skin tone, view recommendations, saved looks, recommendation
/// history.
///
/// Deliberately out of scope for this pass (see CLAUDE.md task brief):
/// virtual try-on / before-after comparison -- no AR/ML pipeline exists.
/// "Skin analysis" here means a skin-tone swatch pick + undertone
/// confirmation, never framed as "AI analysis" in copy.
class BeautyTechScreen extends ConsumerWidget {
  const BeautyTechScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    if (!(authState.value?.hasSession ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beauty')),
        body: Center(
          child: Text('Sign in to set up your skin profile.', style: TextStyle(color: muted)),
        ),
      );
    }

    final asyncProfile = ref.watch(skinProfileControllerProvider);
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;

    return Scaffold(
      appBar: AppBar(title: const Text('Beauty')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(skinProfileControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            asyncProfile.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
              ),
              error: (_, __) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Couldn't load your skin profile", style: TextStyle(color: muted)),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => ref.read(skinProfileControllerProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (profile) => _ProfileStatusCard(profile: profile, heading: heading, muted: muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Quick actions', style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            _QuickActionTile(
              icon: Icons.face_retouching_natural,
              title: 'View Recommendations',
              subtitle: 'Shades matched to your skin tone and undertone',
              onTap: () => context.push(AppRoutes.beautyRecommendations),
            ),
            _QuickActionTile(
              icon: Icons.bookmark_border,
              title: 'Saved Looks',
              subtitle: "Looks you've saved for later",
              onTap: () => context.push(AppRoutes.beautySavedLooks),
            ),
            _QuickActionTile(
              icon: Icons.history,
              title: 'Recommendation History',
              subtitle: 'Past recommendation sessions',
              onTap: () => context.push(AppRoutes.beautyRecommendationHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatusCard extends ConsumerWidget {
  const _ProfileStatusCard({required this.profile, required this.heading, required this.muted});

  final SkinProfile? profile;
  final Color heading;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = profile?.skinToneHex != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasProfile)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorFromHex(profile!.skinToneHex!),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                )
              else
                Icon(Icons.face_outlined, size: 40, color: muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProfile ? 'Skin profile set up' : 'Skin profile not set up yet',
                      style: TextStyle(color: heading, fontWeight: FontWeight.w700),
                    ),
                    if (hasProfile)
                      Text(
                        'Undertone: ${_capitalize(profile!.undertone ?? 'unknown')}',
                        style: TextStyle(color: muted, fontSize: 13),
                      )
                    else
                      Text('Scan your skin tone to get matched shade recommendations',
                          style: TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: hasProfile ? 'Update Skin Tone Scan' : 'Start Skin Tone Scan',
            icon: Icons.colorize,
            expand: true,
            onPressed: () => context.push(AppRoutes.beautyProfileSetup),
          ),
          if (hasProfile) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _confirmReset(context, ref),
                child: Text('Reset profile', style: TextStyle(color: chipText)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset skin profile?'),
        content: const Text('This clears your saved skin tone, undertone, and concerns. You can scan again anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(skinProfileControllerProvider.notifier).reset();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
              child: Icon(icon, color: chipText, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
