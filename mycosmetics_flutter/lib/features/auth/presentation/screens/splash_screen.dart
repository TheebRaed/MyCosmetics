import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Brand splash -- checks for an existing session token and routes into the
/// app shell or to login accordingly. Purely a routing gate; the actual
/// "is this token still valid" check happens lazily on the first
/// authenticated call (see auth_controller.dart's AuthState doc comment).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    // Keep the brand moment on screen briefly even on a fast/local session
    // check -- avoids a jarring instant flash-and-redirect.
    final authState = await ref.read(authControllerProvider.future);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.go(authState.hasSession ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return AuthScaffold(
      showBackButton: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthWordmark(fontSize: 52),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
