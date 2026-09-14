import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import 'admin_analytics_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      AdminDashboardScreen(),
      AdminAnalyticsScreen(),
      AdminOrdersScreen(),
      AdminUsersScreen(),
      AdminDisputesScreen(),
      _AdminProfileTab(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Disputes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Same sign-out pattern every other role's shell uses (customer/partner/
/// driver/staff) — a Profile tab that's always reachable from the bottom
/// nav, rather than a one-off icon tucked into a single tab's AppBar.
class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AppState>().currentAccount!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(radius: 36, child: Text(account.name.substring(0, 1))),
        const SizedBox(height: 12),
        Center(child: Text(account.name, style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text(account.email, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () {
            context.read<AppState>().signOut();
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
          },
        ),
      ],
    );
  }
}
