import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/admin_theme.dart';
import 'core/router/admin_router.dart';

void main() => runApp(const ProviderScope(child: AdminApp()));

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      title: 'MyCosmetics Admin',
      theme: AdminTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
