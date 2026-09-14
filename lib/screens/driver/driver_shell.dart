import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final driver = appState.driverById(appState.currentDriverId)!;
    final pages = [
      const DriverHomeScreen(),
      const DriverEarningsScreen(),
      _DriverProfileTab(driverName: driver.name, vehicle: driver.vehicle),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Tasks'),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Earnings',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab({required this.driverName, required this.vehicle});

  final String driverName;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(radius: 36, child: Text(driverName.substring(0, 1))),
        const SizedBox(height: 12),
        Center(child: Text(driverName, style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text(vehicle, style: Theme.of(context).textTheme.bodyMedium)),
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
