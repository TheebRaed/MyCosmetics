import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_providers.dart';

/// Profile tab home -- the "Profile" bottom-nav tab (`/profile`). Real user
/// info + a menu linking to the real sub-screens built alongside this one
/// (Orders, Addresses, Wishlist, Edit Profile). Notifications, Language
/// Selection, and Privacy Settings are omitted -- see this file's inline
/// notes at each would-be menu entry for why.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;

    final authState = ref.watch(authControllerProvider);

    if (!(authState.value?.hasSession ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Sign in to view your profile.', style: TextStyle(color: muted))),
      );
    }

    final asyncProfile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          asyncProfile.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, __) => AppCard(
              child: Column(
                children: [
                  Text("Couldn't load your profile", style: TextStyle(color: muted)),
                  TextButton(onPressed: () => ref.invalidate(profileControllerProvider), child: const Text('Retry')),
                ],
              ),
            ),
            data: (user) => AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: chipBg,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: chipText, fontWeight: FontWeight.w700, fontSize: 20),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(user.email, style: TextStyle(color: muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: chipText),
                    onPressed: () => context.push(AppRoutes.profileEdit),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuSection(
            heading: heading,
            muted: muted,
            chipText: chipText,
            children: [
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: () => context.push(AppRoutes.orders),
              ),
              _MenuTile(
                icon: Icons.favorite_border,
                label: 'Wishlist',
                onTap: () => context.push(AppRoutes.profileWishlist),
              ),
              _MenuTile(
                icon: Icons.location_on_outlined,
                label: 'Addresses',
                onTap: () => context.push(AppRoutes.profileAddresses),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuSection(
            heading: heading,
            muted: muted,
            chipText: chipText,
            children: [
              _DarkModeTile(heading: heading, muted: muted),
              // Notifications: no customer-facing notification list/preferences
              // endpoint exists (distinct from the admin's notification-campaign
              // features) -- omitted rather than faking an inbox.
              // Language Selection: no flutter_localizations/intl setup exists
              // in this app yet -- real localization is separate infra work,
              // omitted rather than a switcher with no actual translations.
              // Privacy Settings: no backend-backed privacy/consent concept
              // exists -- omitted rather than faking toggles that do nothing.
              _MenuTile(
                icon: Icons.help_outline,
                label: 'Help Center',
                onTap: () => context.push(AppRoutes.profileHelp),
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'About Us',
                onTap: () => context.push(AppRoutes.profileAbout),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuSection(
            heading: heading,
            muted: muted,
            chipText: chipText,
            children: [
              _MenuTile(
                icon: Icons.logout,
                label: 'Log Out',
                destructive: true,
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.children, required this.heading, required this.muted, required this.chipText});

  final List<Widget> children;
  final Color heading;
  final Color muted;
  final Color chipText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) Divider(height: 1, color: muted.withValues(alpha: 0.12)),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final color = destructive ? Colors.red.shade700 : heading;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      trailing: destructive ? null : Icon(Icons.chevron_right, color: muted),
      onTap: onTap,
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile({required this.heading, required this.muted});

  final Color heading;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return SwitchListTile(
      secondary: Icon(Icons.dark_mode_outlined, color: heading),
      title: Text('Dark Mode', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
      subtitle: Text(
        mode == ThemeMode.system ? 'Following system setting' : (isDark ? 'On' : 'Off'),
        style: TextStyle(color: muted, fontSize: 12),
      ),
      value: isDark,
      onChanged: (value) => ref.read(appThemeModeProvider.notifier).setMode(value ? ThemeMode.dark : ThemeMode.light),
    );
  }
}
