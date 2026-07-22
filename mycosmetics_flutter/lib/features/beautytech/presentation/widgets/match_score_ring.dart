import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// The `pulseRing` motif from docs/DESIGN_SYSTEM.md -- scale 1 -> 1.04 with
/// an opacity pulse, used here around the real `ScoreBreakdown.finalScore`
/// match-percentage display on recommendation cards. The percentage itself
/// is a genuine rule-based score (color distance + real usage signals),
/// not a fabricated "AI confidence" -- see beautytech_repository.dart.
class MatchScoreRing extends StatefulWidget {
  const MatchScoreRing({super.key, required this.score, this.size = 56});

  /// 0-100 match score (`ScoreBreakdown.finalScore`).
  final int score;
  final double size;

  @override
  State<MatchScoreRing> createState() => _MatchScoreRingState();
}

class _MatchScoreRingState extends State<MatchScoreRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(curve: Curves.easeInOut, parent: _controller));
    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(CurvedAnimation(curve: Curves.easeInOut, parent: _controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(opacity: _opacity.value, child: child),
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: widget.score.clamp(0, 100) / 100,
                strokeWidth: 4,
                backgroundColor: ringColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            ),
            Text(
              '${widget.score}%',
              style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: widget.size * 0.24),
            ),
          ],
        ),
      ),
    );
  }
}
