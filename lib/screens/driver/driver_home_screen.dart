import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../widgets/status_chip.dart';
import 'driver_task_detail_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.ordersForDriver(appState.currentDriverId).where((o) {
      final isPickupTask = o.pickupDriverId == appState.currentDriverId && o.status == OrderStatus.pickupAssigned;
      final isDeliveryTask = o.deliveryDriverId == appState.currentDriverId &&
          (o.status == OrderStatus.deliveryAssigned || o.status == OrderStatus.outForDelivery);
      return isPickupTask || isDeliveryTask;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My tasks')),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks assigned right now.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final order = tasks[index];
                final isPickup =
                    order.pickupDriverId == appState.currentDriverId && order.status == OrderStatus.pickupAssigned;
                final partner = appState.partnerById(order.partnerId);
                return Card(
                  child: ListTile(
                    leading: Icon(isPickup ? Icons.inventory_2_outlined : Icons.local_shipping_outlined),
                    title: Text('${isPickup ? 'Pickup' : 'Delivery'} • ${order.id}'),
                    subtitle: Text(
                      isPickup
                          ? '${order.pickupAddress.line1} → ${partner.name}'
                          : '${partner.name} → ${order.deliveryAddress.line1}',
                    ),
                    trailing: StatusChip(status: order.status),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DriverTaskDetailScreen(orderId: order.id, isPickup: isPickup),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
