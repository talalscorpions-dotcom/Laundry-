import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.ordersForCustomer(appState.currentCustomer.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet. Browse a laundry partner to get started.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final partner = appState.partnerById(order.partnerId);
                return Card(
                  child: ListTile(
                    title: Text('${order.id} • ${partner.name}'),
                    subtitle: Text('${order.items.length} items • ${formatCurrency(order.total)}'),
                    trailing: StatusChip(status: order.status),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
