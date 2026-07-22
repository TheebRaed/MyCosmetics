import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Reusable card surface matching the `--card-bg` gradient + tinted shadow
/// tokens in docs/DESIGN_SYSTEM.md. Use this instead of a raw `Container`
/// with a hand-rolled `BoxDecoration` so every card stays visually
/// consistent and light/dark stay in sync automatically.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.card,
    this.elevated = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Use the stronger "elevated" shadow recipe (hero cards, modals) instead
  /// of the default resting-card shadow.
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppGradients.card(brightness),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? AppShadows.elevated(brightness) : AppShadows.card(brightness),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
