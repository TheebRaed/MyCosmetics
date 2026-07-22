import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Inline error/success feedback for auth forms -- soft fade-in, rose tint
/// for errors and a muted gold/green tint for success, consistent with the
/// tinted-shadow / no-neutral-grey rule in docs/DESIGN_SYSTEM.md.
class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({super.key, required this.message, this.isError = true});

  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final msg = message;
    if (msg == null || msg.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final successColor = isDark ? AppColorsDark.accentGold : AppColorsLight.accentGold;
    final color = isError ? errorColor : successColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(msg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(msg, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
