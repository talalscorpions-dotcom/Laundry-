import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/order_status_stepper.dart';
import '../../widgets/status_chip.dart';

/// Order detail + "live GPS tracking" while a driver is en route, either
/// heading to the customer for pickup or heading back for delivery.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == orderId);
    final partner = appState.partnerById(order.partnerId);

    Widget? map;
    if (order.status == OrderStatus.pickupAssigned && order.pickupDriverId != null) {
      final driver = appState.driverById(order.pickupDriverId!);
      if (driver != null) {
        map = LiveTrackingMap(
          tracker: appState.locationTracker,
          from: driver.location,
          to: order.pickupAddress.location,
          subjectLabel: '${driver.name} (pickup)',
        );
      }
    } else if ((order.status == OrderStatus.deliveryAssigned || order.status == OrderStatus.outForDelivery) &&
        order.deliveryDriverId != null) {
      final driver = appState.driverById(order.deliveryDriverId!);
      if (driver != null) {
        map = LiveTrackingMap(
          tracker: appState.locationTracker,
          from: partner.location,
          to: order.deliveryAddress.location,
          subjectLabel: '${driver.name} (delivery)',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Order ${order.id}')),
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
          const SizedBox(height: 16),
          if (map != null) ...[map, const SizedBox(height: 16)],
          if (order.status != OrderStatus.cancelled) OrderStatusStepper(status: order.status),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity} × ${item.name}'),
                          Text(formatCurrency(item.lineTotal)),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Total'), Text(formatCurrency(order.total))],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment: ${order.paymentMethod.label} • ${order.paymentStatus.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final entry in order.activityLog.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(entry, style: Theme.of(context).textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (order.status.isActive)
            OutlinedButton(
              onPressed: () => _raiseIssue(context, appState),
              child: const Text('Report an issue with this order'),
            ),
        ],
      ),
    );
  }

  void _raiseIssue(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report an issue'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe what went wrong'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              appState.raiseDispute(orderId: orderId, raisedByRole: 'customer', reason: controller.text.trim());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks — our team will follow up shortly.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
