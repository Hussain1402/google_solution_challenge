import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/ledger/screens/inventory_list_screen.dart';
import '../../features/ledger/screens/sku_detail_screen.dart';
import '../../features/ledger/screens/stock_update_screen.dart';
import '../../features/scout/screens/grid_map_screen.dart';
import '../../features/scout/screens/admin_dashboard_screen.dart';
import '../../features/replenisher/screens/drive_list_screen.dart';
import '../../features/replenisher/screens/drive_detail_screen.dart';
import '../../features/replenisher/screens/pledge_screen.dart';
import '../../features/replenisher/screens/donation_history_screen.dart';
import '../../core/models/drive_model.dart';

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
  static const pledge     = '/drives/:driveId/pledge';
  static const history    = '/history';
}

/// Bridges Riverpod's auth state stream to GoRouter's refreshListenable
/// so the router re-evaluates its redirect whenever auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// go_router configuration with reactive auth-based redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      // While Firebase Auth is still initializing, don't redirect.
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Not logged in → go to login (unless already on auth route).
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // Logged in but on auth route → go to role-specific home.
      if (isLoggedIn && isAuthRoute) {
        final profileAsync = ref.read(userProfileProvider);
        if (profileAsync.isLoading) return null;
        if (profileAsync.value?.role == 'donor') return AppRoutes.drives;
        return AppRoutes.ledger;
      }

      // Role-based guarding
      final profileAsync = ref.read(userProfileProvider);
      if (!profileAsync.isLoading) {
        final role = profileAsync.value?.role;

        // Donor route restriction
        if (role == 'donor') {
          final isDonorRoute = state.matchedLocation.startsWith(AppRoutes.drives) || 
                               state.matchedLocation == AppRoutes.history;
          if (!isDonorRoute) {
            return AppRoutes.drives;
          }
        }

        // Admin route restriction
        if (state.matchedLocation == AppRoutes.scout && role != 'admin') {
          return AppRoutes.ledger; // Kick non-admins back to ledger
        }
      }

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
      GoRoute(
        path: AppRoutes.scout,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.drives,
        builder: (context, state) => const DriveListScreen(),
      ),
      GoRoute(
        path: AppRoutes.driveDetail,
        builder: (context, state) {
          final drive = state.extra as DriveModel;
          return DriveDetailScreen(drive: drive);
        },
      ),
      GoRoute(
        path: AppRoutes.pledge,
        builder: (context, state) {
          final drive = state.extra as DriveModel;
          return PledgeScreen(drive: drive);
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const DonationHistoryScreen(),
      ),
    ],
  );
});
