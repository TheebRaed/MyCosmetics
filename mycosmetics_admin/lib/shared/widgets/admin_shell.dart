import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/router/admin_router.dart';
import '../../features/dashboard/presentation/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _nav = [
    (AdminRoutes.dashboard,     Icons.dashboard_outlined,        'Dashboard'),
    (AdminRoutes.products,      Icons.inventory_2_outlined,      'Products'),
    (AdminRoutes.orders,        Icons.receipt_long_outlined,     'Orders'),
    (AdminRoutes.customers,     Icons.people_outline,            'Customers'),
    (AdminRoutes.inventory,     Icons.warehouse_outlined,        'Inventory'),
    (AdminRoutes.coupons,       Icons.local_offer_outlined,      'Promotions'),
    (AdminRoutes.notifications, Icons.notifications_outlined,    'Notifications'),
    (AdminRoutes.analytics,     Icons.auto_awesome_outlined,     'BeautyTech AI'),
    (AdminRoutes.auditLog,      Icons.history_outlined,          'Audit Log'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final wide     = MediaQuery.of(context).size.width >= 1000;
    final auth     = ref.watch(adminAuthProvider).valueOrNull;

    final sidebar = Container(
      width: 240, color: AdminColors.sidebar,
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.all(20), child: Row(children: [
          Icon(Icons.spa, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MyCosmetics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Admin', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ])),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 8),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: _nav.map((item) {
          final sel = location == item.$1 || (item.$1 == AdminRoutes.customers && location.startsWith('/customers/'));
          return Padding(padding: const EdgeInsets.only(bottom: 4), child: Material(color: sel ? AdminColors.sidebarSel : Colors.transparent, borderRadius: BorderRadius.circular(8), child: ListTile(
            leading: Icon(item.$2, color: sel ? Colors.white : Colors.white60, size: 20),
            title: Text(item.$3, style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () => context.go(item.$1),
          )));
        }).toList())),
        const Divider(color: Colors.white12, height: 1),
        if (auth?.fullName != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text(auth!.fullName!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ListTile(leading: const Icon(Icons.logout, color: Colors.white60, size: 20), title: const Text('Log Out', style: TextStyle(color: Colors.white60, fontSize: 13)), dense: true, onTap: () async {
          await ref.read(adminAuthProvider.notifier).logout();
          if (context.mounted) context.go(AdminRoutes.login);
        }),
        const SizedBox(height: 12),
      ])),
    );

    if (!wide) return Scaffold(appBar: AppBar(title: const Text('MyCosmetics Admin')), drawer: Drawer(child: sidebar), body: child);
    return Scaffold(body: Row(children: [sidebar, Expanded(child: child)]));
  }
}
