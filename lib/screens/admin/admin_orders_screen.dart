import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = List.of(appState.orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('All orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders placed yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final partner = appState.partnerById(order.partnerId);
                return Card(
                  child: ListTile(
                    title: Text('${order.id} • ${partner.name}'),
                    subtitle: Text(formatCurrency(order.total)),
                    trailing: StatusChip(status: order.status),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: order.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
