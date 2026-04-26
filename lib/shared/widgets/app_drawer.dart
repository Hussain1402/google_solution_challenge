import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/router/app_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('The Ledger'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.go(AppRoutes.ledger);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('The Grid'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.go(AppRoutes.grid);
            },
          ),
        ],
      ),
    );
  }
}
