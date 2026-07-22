import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Static content screen -- `/profile/about`. No backend/config source for
/// app metadata exists, so version/build info is omitted rather than
/// hardcoded and left to silently rot.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.spa_outlined, color: chipText, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('MyCosmetics', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: heading)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'MyCosmetics is a BeautyTech shopping experience -- skin analysis, AI-guided shade '
              'matching, and virtual try-on, paired with a full cosmetics catalog and checkout.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
