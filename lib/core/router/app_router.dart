import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/ledger/screens/inventory_list_screen.dart';
import '../../features/ledger/screens/sku_detail_screen.dart';
import '../../features/ledger/screens/stock_update_screen.dart';
import '../../features/scout/screens/grid_map_screen.dart';

/// Route path constants.
class AppRoutes {
  static const login      = '/login';
  static const register   = '/register';
  static const ledger     = '/ledger';
  static const skuDetail  = '/ledger/:skuId';
  static const stockIn    = '/ledger/:skuId/stock-in';
  static const stockOut   = '/ledger/:skuId/stock-out';
  static const grid       = '/grid';
  static const scout      = '/scout';
  static const drives     = '/drives';
  static const driveDetail = '/drives/:driveId';
}

/// go_router configuration with role-based redirect.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (e, st) => false,
      );
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Not logged in → go to login (unless already on auth route).
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // Logged in but on auth route → go to role-based home.
      if (isLoggedIn && isAuthRoute) return AppRoutes.ledger;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.ledger,
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.skuDetail,
        builder: (context, state) {
          final skuId = state.pathParameters['skuId']!;
          return SkuDetailScreen(skuId: skuId);
        },
      ),
      GoRoute(
        path: AppRoutes.stockIn,
        builder: (context, state) {
          final skuId = state.pathParameters['skuId']!;
          return StockUpdateScreen(skuId: skuId, eventType: 'STOCK_IN');
        },
      ),
      GoRoute(
        path: AppRoutes.stockOut,
        builder: (context, state) {
          final skuId = state.pathParameters['skuId']!;
          return StockUpdateScreen(skuId: skuId, eventType: 'STOCK_OUT');
        },
      ),
      GoRoute(
        path: AppRoutes.grid,
        builder: (context, state) => const GridMapScreen(),
      ),
    ],
  );
});
