import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_code_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/beautytech/presentation/screens/beautytech_screen.dart';
import '../../features/beautytech/presentation/screens/recommendation_history_screen.dart';
import '../../features/beautytech/presentation/screens/recommendations_screen.dart';
import '../../features/beautytech/presentation/screens/saved_look_detail_screen.dart';
import '../../features/beautytech/presentation/screens/saved_looks_screen.dart';
import '../../features/beautytech/presentation/screens/skin_profile_setup_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_confirmation_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/product_details/presentation/screens/product_details_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/wishlist_screen.dart';
import '../../shared/widgets/app_shell.dart';

part 'app_router.g.dart';

/// Route paths for the customer app's 5 bottom-nav tabs. Exactly these 5
/// per CLAUDE.md -- do not add more without updating that doc. Auth routes
/// live outside the shell (top-level, no bottom nav).
abstract class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const beauty = '/beauty';
  static const cart = '/cart';
  static const profile = '/profile';

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetCode = '/reset-code';
  static const resetPassword = '/reset-password';

  /// Product Details (PDP) -- top-level route (pushed on top of the shell,
  /// no bottom nav) reachable from any `ProductCard` tap in Home/Search.
  static const productDetailsPattern = '/product/:id';
  static String productDetails(int id) => '/product/$id';

  /// Checkout -- top-level route (pushed on top of the shell, no bottom
  /// nav) reached from Cart's "Proceed to Checkout" action.
  static const checkout = '/checkout';

  /// Order confirmation -- reached after a successful `OrderEndpoint.checkout()`.
  /// The created `OrderDetail` is passed via `extra` (see order_confirmation_screen.dart) --
  /// no separate re-fetch-by-id round trip needed right after creation.
  static const orderConfirmation = '/order-confirmation';

  /// Orders -- reachable from Profile, not a bottom-nav tab (exactly 5 tabs
  /// per CLAUDE.md). Both pushed on top of the shell.
  static const orders = '/profile/orders';
  static const orderDetailsPattern = '/profile/orders/:id';
  static String orderDetails(int id) => '/profile/orders/$id';

  /// Profile sub-screens -- all reached from the Profile tab, pushed on top
  /// of the shell (no bottom nav on these).
  static const profileEdit = '/profile/edit';
  static const profileAddresses = '/profile/addresses';
  static const profileWishlist = '/profile/wishlist';
  static const profileHelp = '/profile/help';
  static const profileAbout = '/profile/about';

  /// BeautyTech sub-screens -- all reached from the Beauty tab, pushed on
  /// top of the shell (no bottom nav on these). "Skin tone scan" per the
  /// honesty framing in CLAUDE.md -- there is no camera/ML pipeline, this
  /// is a swatch pick + undertone confirmation.
  static const beautyProfileSetup = '/beauty/scan';
  static const beautyRecommendations = '/beauty/recommendations';
  static const beautyRecommendationHistory = '/beauty/recommendations/history';
  static const beautySavedLooks = '/beauty/saved-looks';

  /// Saved look detail -- the `SavedLook` is passed via `extra` (see
  /// saved_look_detail_screen.dart), no single-get-by-id endpoint exists.
  static const beautySavedLookDetail = '/beauty/saved-looks/detail';
}

const _authRoutes = {
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.resetCode,
  AppRoutes.resetPassword,
};

/// Bridges Riverpod's [AuthController] state into a [Listenable] so
/// go_router can re-run its redirect whenever sign-in state changes (e.g.
/// after logout from deep within the shell).
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

@riverpod
GoRouter appRouter(Ref ref) {
  final refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Splash owns its own navigation once the session check resolves --
      // never redirect away from it.
      if (location == AppRoutes.splash) return null;

      // While the session check is in flight, hold on whatever route was
      // requested rather than bouncing to login and back.
      if (!authState.hasValue) return null;

      final hasSession = authState.value!.hasSession;
      final onAuthRoute = _authRoutes.contains(location);

      if (!hasSession && !onAuthRoute) return AppRoutes.login;
      if (hasSession && onAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.resetCode, builder: (_, __) => const ResetCodeScreen()),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) => ResetPasswordScreen(token: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.productDetailsPattern,
        builder: (_, state) => ProductDetailsScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: AppRoutes.checkout, builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        builder: (_, state) => OrderConfirmationScreen(orderDetail: state.extra as OrderDetail),
      ),
      GoRoute(path: AppRoutes.orders, builder: (_, __) => const OrderListScreen()),
      GoRoute(
        path: AppRoutes.orderDetailsPattern,
        builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: AppRoutes.profileEdit, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.profileAddresses, builder: (_, __) => const AddressesScreen()),
      GoRoute(path: AppRoutes.profileWishlist, builder: (_, __) => const WishlistScreen()),
      GoRoute(path: AppRoutes.profileHelp, builder: (_, __) => const HelpCenterScreen()),
      GoRoute(path: AppRoutes.profileAbout, builder: (_, __) => const AboutScreen()),
      GoRoute(path: AppRoutes.beautyProfileSetup, builder: (_, __) => const SkinProfileSetupScreen()),
      GoRoute(path: AppRoutes.beautyRecommendations, builder: (_, __) => const RecommendationsScreen()),
      GoRoute(path: AppRoutes.beautyRecommendationHistory, builder: (_, __) => const RecommendationHistoryScreen()),
      GoRoute(path: AppRoutes.beautySavedLooks, builder: (_, __) => const SavedLooksScreen()),
      GoRoute(
        path: AppRoutes.beautySavedLookDetail,
        builder: (_, state) => SavedLookDetailScreen(look: state.extra as SavedLook),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.beauty, builder: (_, __) => const BeautyTechScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
