import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import 'partner_order_detail_screen.dart';

class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.ordersForPartner(appState.currentPartnerId);
    final active = orders.where((o) => o.status.isActive).length;
    final revenue = orders.fold<double>(0, (s, o) => s + o.partnerPayout);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Active orders', value: '$active')),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Net earnings', value: formatCurrency(revenue))),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No orders yet.')),
          for (final order in orders)
            Card(
              child: ListTile(
                title: Text(order.id),
                subtitle: Text(
                  '${order.items.length} items • ${formatCurrency(order.subtotal)} • you keep ${formatCurrency(order.partnerPayout)}',
                ),
                trailing: StatusChip(status: order.status),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PartnerOrderDetailScreen(orderId: order.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
