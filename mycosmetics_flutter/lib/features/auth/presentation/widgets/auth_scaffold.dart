import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';

/// Shared chrome for every auth screen: soft gradient wash background, a
/// gentle fade+scale entrance (the "unhurried, luxury" motion language from
/// docs/DESIGN_SYSTEM.md -- no jarring Material defaults), optional back
/// button, and a consistent scroll/padding shell.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = true,
  });

  final Widget child;
  final bool showBackButton;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.98, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bodyBg = isDark ? AppColorsDark.bodyBg : AppColorsLight.bodyBg;
    final washColor = isDark ? AppColorsDark.pageWashGold : AppColorsLight.pageWashRoseGold.withValues(alpha: 0.18);

    return Scaffold(
      backgroundColor: bodyBg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [washColor, bodyBg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                    child: widget.child,
                  ),
                ),
              ),
              if (widget.showBackButton && Navigator.of(context).canPop())
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "My Cosmetics" wordmark in Dancing Script -- brand accent only, never
/// used for body copy per docs/DESIGN_SYSTEM.md.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    return Text('My Cosmetics', style: AppTextStyles.dancingScript(color: color, fontSize: fontSize));
  }
}
