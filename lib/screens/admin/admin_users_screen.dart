import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';

/// "Oversee all users" — a simple customer/partner/driver directory. A
/// production build would add suspend/verify actions backed by real
/// account state.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Customers')),
                ButtonSegment(value: 1, label: Text('Partners')),
                ButtonSegment(value: 2, label: Text('Drivers')),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(child: _buildList(appState)),
        ],
      ),
    );
  }

  Widget _buildList(AppState appState) {
    switch (_segment) {
      case 0:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final customer in appState.customers)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(customer.name),
                  subtitle: Text(
                    '${customer.phone.isEmpty ? 'No phone on file' : customer.phone} • '
                    '${appState.ordersForCustomer(customer.id).length} orders',
                  ),
                  trailing: Text('${customer.addresses.length} address(es)'),
                ),
              ),
          ],
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final partner in appState.partners)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(partner.name),
                  subtitle: Text(
                    '${partner.area} • ${appState.ordersForPartner(partner.id).length} orders • '
                    '${(partner.commissionRate * 100).toStringAsFixed(0)}% commission',
                  ),
                  trailing: Text(partner.isOpen ? 'Open' : 'Closed'),
                ),
              ),
          ],
        );
      default:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final driver in appState.drivers)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.two_wheeler),
                  title: Text(driver.name),
                  subtitle: Text('${driver.vehicle} • ★ ${driver.rating.toStringAsFixed(1)}'),
                  trailing: Text(driver.isAvailable ? 'Available' : 'Busy'),
                ),
              ),
          ],
        );
    }
  }
}
