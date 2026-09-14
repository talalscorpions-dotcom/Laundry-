import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import 'staff_queue_screen.dart';

/// The hub operations team's app: a single working queue of every order
/// currently at the hub (dropped off, being inspected, processed, or
/// quality-checked) plus a profile/sign-out tab. Unlike Customer/Partner/
/// Driver, staff aren't tied to one linked record — see the seeded
/// `staff@laundrygo.com` account (no `linkedId`) in `mock_data.dart`.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const StaffQueueScreen(),
      const _StaffProfileTab(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse),
            label: 'Hub queue',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StaffProfileTab extends StatelessWidget {
  const _StaffProfileTab();

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
