import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final isDonor = userProfileAsync.value?.role == 'donor';
    final isAdmin = userProfileAsync.value?.role == 'admin';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: kBlue),
            child: Text(
              'ReliefHub AI',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isDonor) ...[
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('The Ledger'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.ledger);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('The Grid'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.grid);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: Text(isDonor ? 'Active Drives' : 'Donation Drives'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.drives);
            },
          ),
          if (isDonor) ...[
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Donation History'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.history);
              },
            ),
          ],
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: kBlue),
              title: const Text('The Scout (AI)', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.scout);
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: kRed),
            title: const Text('Log Out', style: TextStyle(color: kRed)),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
