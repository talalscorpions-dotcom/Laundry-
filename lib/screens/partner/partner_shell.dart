import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../routing/app_routes.dart';
import 'partner_dashboard_screen.dart';
import 'partner_pricing_screen.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partner = appState.partnerById(appState.currentPartnerId);
    final pages = [
      const PartnerDashboardScreen(),
      const PartnerPricingScreen(),
      _PartnerProfileTab(partnerName: partner.name),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.sell_outlined), selectedIcon: Icon(Icons.sell), label: 'Pricing'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}

class _PartnerProfileTab extends StatelessWidget {
  const _PartnerProfileTab({required this.partnerName});

  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(radius: 36, child: Text(partnerName.substring(0, 1))),
        const SizedBox(height: 12),
        Center(child: Text(partnerName, style: Theme.of(context).textTheme.titleLarge)),
        Center(child: Text('Laundry partner', style: Theme.of(context).textTheme.bodyMedium)),
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
