import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../providers/beautytech_providers.dart';
import '../widgets/scan_line_overlay.dart';
import '../widgets/skin_tone_swatches.dart';

/// Skin tone scan / update screen -- swatch picker + undertone picker +
/// optional concerns text. NOT an AI/ML analysis (see CLAUDE.md task
/// brief): the user is picking/confirming a swatch. Copy calls this a
/// "skin tone scan", never "AI analysis".
///
/// On confirm: a brief `scanLine` "analyzing" animation beat plays, then
/// `skinAnalysis.submit()` is called (which upserts the profile
/// server-side), followed by `skinProfile.save()` only if concerns text was
/// entered (submit() doesn't accept concerns -- see beautytech_repository.dart).
class SkinProfileSetupScreen extends ConsumerStatefulWidget {
  const SkinProfileSetupScreen({super.key});

  @override
  ConsumerState<SkinProfileSetupScreen> createState() => _SkinProfileSetupScreenState();
}

class _SkinProfileSetupScreenState extends ConsumerState<SkinProfileSetupScreen> {
  String? _selectedHex;
  String? _selectedUndertone;
  final _concernsController = TextEditingController();
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(skinProfileControllerProvider).value;
    _selectedHex = existing?.skinToneHex;
    _selectedUndertone = existing?.undertone;
    _concernsController.text = existing?.concerns ?? '';
  }

  @override
  void dispose() {
    _concernsController.dispose();
    super.dispose();
  }

  bool get _canConfirm => _selectedHex != null && _selectedUndertone != null && !_scanning;

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() => _scanning = true);

    // Brief `scanLine` "analyzing" beat before submitting -- purely a UI
    // pacing beat, no actual processing happens client-side (there is no
    // ML pipeline; see doc comment above).
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final error = await ref.read(skinProfileControllerProvider.notifier).submitScan(
          skinToneHex: _selectedHex!,
          undertone: _selectedUndertone!,
          concerns: _concernsController.text,
        );

    if (!mounted) return;
    setState(() => _scanning = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skin tone scan saved')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      appBar: AppBar(title: const Text('Skin Tone Scan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Pick the swatch that best matches your skin tone. This is a color match, not an automated analysis.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_scanning)
            _ScanningBeat(hex: _selectedHex!)
          else ...[
            Text('Skin tone', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            SkinToneSwatchGrid(
              selectedHex: _selectedHex,
              onSelected: (hex) => setState(() => _selectedHex = hex),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Undertone', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            UndertonePicker(
              selected: _selectedUndertone,
              onSelected: (v) => setState(() => _selectedUndertone = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Concerns (optional)', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _concernsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. dryness, redness, oiliness',
                hintStyle: TextStyle(color: muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PillButton(
              label: 'Confirm Skin Tone Scan',
              icon: Icons.check,
              expand: true,
              onPressed: _canConfirm ? _confirm : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanningBeat extends StatelessWidget {
  const _ScanningBeat({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    const height = 160.0;

    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(color: _colorFromHex(hex), shape: BoxShape.circle),
                  ),
                ),
                const ScanLineOverlay(height: height),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Matching your shade...', style: TextStyle(color: muted)),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
