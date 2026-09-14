import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';

/// "Master dashboard to oversee all users, track revenue commissions...
/// and manage analytics."
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final revenueByPartner = <String, double>{};
    for (final order in appState.orders.where((o) => o.status != OrderStatus.cancelled)) {
      revenueByPartner[order.partnerId] = (revenueByPartner[order.partnerId] ?? 0) + order.total;
    }
    final topPartners = revenueByPartner.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                label: 'Gross merchandise value',
                value: formatCurrency(appState.totalGmv),
                icon: Icons.trending_up,
              ),
              StatCard(
                label: 'Commission revenue',
                value: formatCurrency(appState.totalCommission),
                icon: Icons.account_balance_wallet_outlined,
              ),
              StatCard(
                label: 'Active orders',
                value: '${appState.activeOrderCount}',
                icon: Icons.local_shipping_outlined,
              ),
              StatCard(
                label: 'Completed orders',
                value: '${appState.completedOrderCount}',
                icon: Icons.check_circle_outline,
              ),
              StatCard(label: 'Partners', value: '${appState.partners.length}', icon: Icons.storefront_outlined),
              StatCard(label: 'Drivers', value: '${appState.drivers.length}', icon: Icons.two_wheeler_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Text('Operations pipeline — where every order sits right now', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              StatCard(label: 'New orders', value: '${appState.newOrderCount}', icon: Icons.fiber_new_outlined),
              StatCard(
                label: 'Pickup pending',
                value: '${appState.pickupPendingCount}',
                icon: Icons.pending_actions_outlined,
              ),
              StatCard(label: 'At the hub', value: '${appState.atHubCount}', icon: Icons.warehouse_outlined),
              StatCard(
                label: 'Inspecting',
                value: '${appState.inspectingCount}',
                icon: Icons.fact_check_outlined,
              ),
              StatCard(label: 'Processing', value: '${appState.processingCount}', icon: Icons.local_laundry_service_outlined),
              StatCard(label: 'Quality check', value: '${appState.qualityCheckCount}', icon: Icons.rule_outlined),
              StatCard(
                label: 'Ready for delivery',
                value: '${appState.readyForDeliveryCount}',
                icon: Icons.inventory_2_outlined,
              ),
              StatCard(
                label: 'Out for delivery',
                value: '${appState.outForDeliveryCount}',
                icon: Icons.local_shipping_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Revenue by partner', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (topPartners.isEmpty) const Text('No orders yet.'),
          for (final entry in topPartners)
            Card(
              child: ListTile(
                title: Text(appState.partnerById(entry.key).name),
                trailing: Text(formatCurrency(entry.value)),
              ),
            ),
        ],
      ),
    );
  }
}
