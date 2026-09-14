import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/user_models.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';

/// Where a partner accepts orders, moves items through washing/ironing/ready,
/// and hands off to a driver at each leg — the "coordinate with drivers"
/// requirement.
class PartnerOrderDetailScreen extends StatelessWidget {
  const PartnerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == orderId);

    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup', style: Theme.of(context).textTheme.titleSmall),
                  Text('${order.pickupAddress.line1}, ${order.pickupAddress.city}'),
                  Text(order.pickupSlot.label),
                  const SizedBox(height: 12),
                  Text('Delivery', style: Theme.of(context).textTheme.titleSmall),
                  Text('${order.deliveryAddress.line1}, ${order.deliveryAddress.city}'),
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
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.quantityAdjustedByStaff
                                ? '${item.actualQuantity} × ${item.name} (${item.serviceType.label}) — ordered ${item.quantity}'
                                : '${item.actualQuantity} × ${item.name} (${item.serviceType.label})',
                          ),
                          Text(formatCurrency(item.lineTotal)),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Order subtotal'), Text(formatCurrency(order.subtotal))],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Platform commission (${(order.commissionRate * 100).toStringAsFixed(0)}%)'),
                      Text('- ${formatCurrency(order.commissionAmount)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('You receive', style: Theme.of(context).textTheme.titleSmall),
                      Text(formatCurrency(order.partnerPayout), style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._actionsFor(context, appState, order),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(BuildContext context, AppState appState, LaundryOrder order) {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          ElevatedButton(
            onPressed: () => appState.acceptOrder(order.id),
            child: const Text('Accept order'),
          ),
        ];
      case OrderStatus.accepted:
        final pickupDrivers = appState.driversAvailableForSlot(order.pickupSlot);
        return [
          Text('Assign a driver for pickup', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (pickupDrivers.isEmpty)
            const Text(
              'Fully booked — every driver rostered for this time slot is already covering another pickup.',
              style: TextStyle(color: Colors.red),
            )
          else
            ..._driverTiles(pickupDrivers, (driverId) => appState.assignPickupDriver(order.id, driverId)),
        ];
      case OrderStatus.pickupAssigned:
        return [const Text('Waiting for the driver to collect the items from the customer.')];
      case OrderStatus.pickedUp:
        return [const Text('Picked up — waiting for the driver to drop it off at the laundry hub.')];
      case OrderStatus.atHub:
        return [const Text('At the laundry hub — waiting for staff to start inspection.')];
      case OrderStatus.inspecting:
        return [const Text('Hub staff are inspecting the bag (verifying item counts, checking for damage).')];
      case OrderStatus.processing:
        return [
          Text(
            order.processingStage != null
                ? 'Being processed by hub staff — currently ${order.processingStage!.label.toLowerCase()}.'
                : 'Being processed by hub staff.',
          ),
        ];
      case OrderStatus.qualityCheck:
        return [const Text('Hub staff are running the quality check.')];
      case OrderStatus.readyForDelivery:
        final deliveryDrivers = appState.drivers.where((d) => d.isAvailable).toList();
        return [
          Text('Assign a driver for delivery', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (deliveryDrivers.isEmpty)
            const Text('No drivers currently on shift.', style: TextStyle(color: Colors.red))
          else
            ..._driverTiles(deliveryDrivers, (driverId) => appState.assignDeliveryDriver(order.id, driverId)),
        ];
      case OrderStatus.deliveryAssigned:
        return [const Text('Waiting for the driver to start the delivery.')];
      case OrderStatus.outForDelivery:
        return [const Text('Order is on its way to the customer.')];
      case OrderStatus.delivered:
        return [const Text('Order completed.')];
      case OrderStatus.cancelled:
        return [const Text('This order was cancelled.')];
    }
  }

  List<Widget> _driverTiles(List<Driver> drivers, void Function(String driverId) onAssign) {
    return [
      for (final driver in drivers)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.two_wheeler),
          title: Text(driver.name),
          subtitle: Text(driver.vehicle),
          trailing: TextButton(
            onPressed: () => onAssign(driver.id),
            child: const Text('Assign'),
          ),
        ),
    ];
  }
}
