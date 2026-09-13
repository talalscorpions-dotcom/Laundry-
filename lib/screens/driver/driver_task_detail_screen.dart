import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../widgets/live_tracking_map.dart';

/// "Receive pickup tasks, view optimized map routes, update delivery
/// milestones" — the driver-facing task screen with a live tracking map and
/// a single milestone action button that advances with the order's status.
class DriverTaskDetailScreen extends StatelessWidget {
  const DriverTaskDetailScreen({super.key, required this.orderId, required this.isPickup});

  final String orderId;
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == orderId);
    final partner = appState.partnerById(order.partnerId);
    final driver = appState.driverById(appState.currentDriverId)!;

    final from = driver.location;
    final to = isPickup ? order.pickupAddress.location : order.deliveryAddress.location;

    return Scaffold(
      appBar: AppBar(title: Text('${isPickup ? 'Pickup' : 'Delivery'} • ${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LiveTrackingMap(tracker: appState.locationTracker, from: from, to: to, subjectLabel: 'You'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPickup ? 'Pickup from' : 'Deliver to', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    isPickup
                        ? '${order.pickupAddress.line1}, ${order.pickupAddress.city}'
                        : '${order.deliveryAddress.line1}, ${order.deliveryAddress.city}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPickup ? 'Then drop off at ${partner.name}' : 'Coming from ${partner.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text('Items: ${order.items.map((i) => '${i.quantity}x ${i.name}').join(', ')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _actionButton(context, appState, order),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, AppState appState, LaundryOrder order) {
    if (isPickup && order.status == OrderStatus.pickupAssigned) {
      return ElevatedButton(
        onPressed: () {
          appState.markPickedUp(order.id);
          Navigator.pop(context);
        },
        child: const Text('Mark items picked up'),
      );
    }
    if (!isPickup && order.status == OrderStatus.deliveryAssigned) {
      return ElevatedButton(
        onPressed: () => appState.markOutForDelivery(order.id),
        child: const Text('Start delivery'),
      );
    }
    if (!isPickup && order.status == OrderStatus.outForDelivery) {
      return ElevatedButton(
        onPressed: () {
          appState.markDelivered(order.id);
          Navigator.pop(context);
        },
        child: const Text('Mark delivered'),
      );
    }
    return const SizedBox.shrink();
  }
}
