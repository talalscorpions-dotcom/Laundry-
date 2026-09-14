import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../widgets/status_chip.dart';
import 'staff_order_detail_screen.dart';

const _hubStatuses = [
  OrderStatus.atHub,
  OrderStatus.inspecting,
  OrderStatus.processing,
  OrderStatus.qualityCheck,
];

/// Every order currently inside the hub's four walls, across all partners —
/// the "internal processing pipeline" queue a laundry's own ops team works
/// from, as distinct from a single partner's own order list.
class StaffQueueScreen extends StatelessWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final queue = appState.orders.where((o) => _hubStatuses.contains(o.status)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Hub queue')),
      body: queue.isEmpty
          ? const Center(child: Text('Nothing at the hub right now.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final order = queue[index];
                final partner = appState.partnerById(order.partnerId);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_laundry_service_outlined),
                    title: Text('${order.bagId ?? order.id} • ${partner.name}'),
                    subtitle: Text(
                      order.status == OrderStatus.processing && order.processingStage != null
                          ? 'Processing — ${order.processingStage!.label}'
                          : order.status.label,
                    ),
                    trailing: StatusChip(status: order.status),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StaffOrderDetailScreen(orderId: order.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
