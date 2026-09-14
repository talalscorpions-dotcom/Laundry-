import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../widgets/live_tracking_map.dart';

/// "Receive pickup tasks, view optimized map routes, update delivery
/// milestones" — the driver-facing task screen with a live tracking map and
/// a single milestone action button that advances with the order's status.
class DriverTaskDetailScreen extends StatefulWidget {
  const DriverTaskDetailScreen({super.key, required this.orderId, required this.isPickup});

  final String orderId;
  final bool isPickup;

  @override
  State<DriverTaskDetailScreen> createState() => _DriverTaskDetailScreenState();
}

class _DriverTaskDetailScreenState extends State<DriverTaskDetailScreen> {
  final _otpController = TextEditingController();
  String? _otpError;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == widget.orderId);
    final partner = appState.partnerById(order.partnerId);
    final driver = appState.driverById(appState.currentDriverId)!;
    final isPickup = widget.isPickup;

    // After pickup, the driver's next stop is the hub (the partner), not the
    // customer they already collected from.
    final from = driver.location;
    final to = isPickup
        ? (order.status == OrderStatus.pickedUp ? partner.location : order.pickupAddress.location)
        : order.deliveryAddress.location;

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
                  Text(
                    isPickup
                        ? (order.status == OrderStatus.pickedUp ? 'Drop off at' : 'Pickup from')
                        : 'Deliver to',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    isPickup
                        ? (order.status == OrderStatus.pickedUp
                            ? '${partner.name} (${partner.area})'
                            : '${order.pickupAddress.line1}, ${order.pickupAddress.city}')
                        : '${order.deliveryAddress.line1}, ${order.deliveryAddress.city}',
                  ),
                  const SizedBox(height: 8),
                  if (isPickup && order.status != OrderStatus.pickedUp)
                    Text('Then drop off at ${partner.name}', style: Theme.of(context).textTheme.bodySmall)
                  else if (!isPickup)
                    Text('Coming from ${partner.name}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text('Items: ${order.items.map((i) => '${i.actualQuantity}x ${i.name}').join(', ')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _actionArea(context, appState, order),
        ],
      ),
    );
  }

  Widget _actionArea(BuildContext context, AppState appState, LaundryOrder order) {
    if (widget.isPickup && order.status == OrderStatus.pickupAssigned) {
      return ElevatedButton(
        onPressed: () {
          appState.markPickedUp(order.id);
          Navigator.pop(context);
        },
        child: const Text('Mark items picked up'),
      );
    }
    if (widget.isPickup && order.status == OrderStatus.pickedUp) {
      return ElevatedButton(
        onPressed: () {
          appState.markDroppedOffAtHub(order.id);
          Navigator.pop(context);
        },
        child: const Text('Mark dropped off at hub'),
      );
    }
    if (!widget.isPickup && order.status == OrderStatus.deliveryAssigned) {
      return ElevatedButton(
        onPressed: () => appState.markOutForDelivery(order.id),
        child: const Text('Start delivery'),
      );
    }
    if (!widget.isPickup && order.status == OrderStatus.outForDelivery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask the customer for their delivery code and enter it below to confirm.'),
          const SizedBox(height: 8),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: 'Delivery code',
              border: const OutlineInputBorder(),
              errorText: _otpError,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final success = appState.confirmDelivery(order.id, _otpController.text);
              if (success) {
                Navigator.pop(context);
              } else {
                setState(() => _otpError = 'Incorrect code — ask the customer to double-check it.');
              }
            },
            child: const Text('Confirm delivery'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
