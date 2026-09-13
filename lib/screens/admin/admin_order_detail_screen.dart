import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == orderId);
    final partner = appState.partnerById(order.partnerId);

    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(partner.name, style: Theme.of(context).textTheme.titleLarge),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('Customer: ${appState.customer.name}'),
          const SizedBox(height: 8),
          Text('Items subtotal: ${formatCurrency(order.subtotal)}'),
          Text('Delivery fee: ${formatCurrency(order.deliveryFee)}'),
          Text('Order total: ${formatCurrency(order.total)}'),
          Text('Commission (${(order.commissionRate * 100).toStringAsFixed(0)}%): ${formatCurrency(order.commissionAmount)}'),
          Text('Partner payout: ${formatCurrency(order.partnerPayout)}'),
          const SizedBox(height: 16),
          Text('Activity log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in order.activityLog) Text(entry, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          if (order.status.isActive)
            OutlinedButton(
              onPressed: () {
                appState.cancelOrder(order.id, 'Cancelled by admin');
                Navigator.pop(context);
              },
              child: const Text('Cancel order (admin override)'),
            ),
        ],
      ),
    );
  }
}
