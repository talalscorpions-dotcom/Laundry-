import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import 'customer_home_screen.dart';
import 'order_history_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final pages = [
      const CustomerHomeScreen(),
      const OrderHistoryScreen(),
      _CustomerProfileTab(customerName: appState.currentCustomer.name, phone: appState.currentCustomer.phone),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(Icons.local_laundry_service),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
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

class _CustomerProfileTab extends StatelessWidget {
  const _CustomerProfileTab({required this.customerName, required this.phone});

  final String customerName;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(radius: 36, child: Text(customerName.substring(0, 1))),
        const SizedBox(height: 12),
        Center(child: Text(customerName, style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text(phone, style: Theme.of(context).textTheme.bodyMedium)),
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
