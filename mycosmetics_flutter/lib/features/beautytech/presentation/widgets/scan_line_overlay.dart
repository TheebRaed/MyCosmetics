import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// The `scanLine` motif from docs/DESIGN_SYSTEM.md -- a vertical line
/// sweeping 8% -> 88% -> 8% of the container height, looping. Used only for
/// the skin-tone-scan "analyzing" beat on [SkinProfileSetupScreen] -- not
/// used elsewhere per the task brief (this is a luxury/soft motion, not
/// gratuitous decoration).
class ScanLineOverlay extends StatefulWidget {
  const ScanLineOverlay({super.key, required this.height, this.color});

  final double height;
  final Color? color;

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _position = Tween<double>(begin: 0.08, end: 0.88).animate(CurvedAnimation(curve: Curves.easeInOut, parent: _controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = widget.color ?? (isDark ? AppColorsDark.accentGold : AppColorsLight.accentGold);

    return AnimatedBuilder(
      animation: _position,
      builder: (context, _) {
        return Positioned(
          top: widget.height * _position.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: lineColor,
              boxShadow: AppShadows.glowDot(color: lineColor),
            ),
          ),
        );
      },
    );
  }
}
