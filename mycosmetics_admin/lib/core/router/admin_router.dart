import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/dashboard/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/coupons/presentation/screens/coupons_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/analytics/presentation/screens/beautytech_analytics_screen.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../shared/widgets/admin_shell.dart';
part 'admin_router.g.dart';

abstract class AdminRoutes {
  static const login          = '/login';
  static const dashboard      = '/';
  static const products       = '/products';
  static const orders         = '/orders';
  static const customers      = '/customers';
  static const customerDetail = '/customers/:id';
  static const inventory      = '/inventory';
  static const coupons        = '/coupons';
  static const notifications  = '/notifications';
  static const analytics      = '/analytics';
  static const auditLog       = '/audit';
}

@riverpod
GoRouter adminRouter(Ref ref) {
  final authState = ref.watch(adminAuthProvider);
  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    redirect: (_, state) {
      if (authState.isLoading) return null;
      final isAuth  = authState.valueOrNull?.isAuthenticated ?? false;
      final isLogin = state.matchedLocation == AdminRoutes.login;
      if (!isAuth && !isLogin) return AdminRoutes.login;
      if (isAuth  && isLogin)  return AdminRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AdminRoutes.login, builder: (_, __) => const AdminLoginScreen()),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: AdminRoutes.dashboard,      builder: (_, __) => const DashboardScreen()),
          GoRoute(path: AdminRoutes.products,       builder: (_, __) => const ProductsScreen()),
          GoRoute(path: AdminRoutes.orders,         builder: (_, __) => const OrdersScreen()),
          GoRoute(path: AdminRoutes.customers,      builder: (_, __) => const CustomersScreen()),
          GoRoute(path: AdminRoutes.customerDetail, builder: (_, s)  => CustomerDetailScreen(userId: int.parse(s.pathParameters['id']!))),
          GoRoute(path: AdminRoutes.inventory,      builder: (_, __) => const InventoryScreen()),
          GoRoute(path: AdminRoutes.coupons,        builder: (_, __) => const CouponsScreen()),
          GoRoute(path: AdminRoutes.notifications,  builder: (_, __) => const AdminNotificationsScreen()),
          GoRoute(path: AdminRoutes.analytics,      builder: (_, __) => const BeautyTechAnalyticsScreen()),
          GoRoute(path: AdminRoutes.auditLog,       builder: (_, __) => const AuditLogScreen()),
        ],
      ),
    ],
  );
}
