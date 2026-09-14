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
          if (order.status == OrderStatus.outForDelivery && order.deliveryOtp != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your delivery code', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryOtp!,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 4),
                    ),
                    const SizedBox(height: 4),
                    const Text('Give this to the driver when your order arrives to confirm delivery.'),
                  ],
                ),
              ),
            ),
          if (order.status == OrderStatus.outForDelivery && order.deliveryOtp != null) const SizedBox(height: 16),
          if (order.bagId != null || order.inspectionNotes.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('At the laundry', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (order.bagId != null) Text('Bag ID: ${order.bagId}'),
                    if (order.inspectionNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Notes from inspection & quality check', style: Theme.of(context).textTheme.titleSmall),
                      for (final note in order.inspectionNotes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $note', style: Theme.of(context).textTheme.bodySmall),
                        ),
                    ],
                    if (order.inspectionPhotoNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Photos: ${order.inspectionPhotoNames.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          if (order.bagId != null || order.inspectionNotes.isNotEmpty) const SizedBox(height: 16),
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
                                ? '${item.actualQuantity} × ${item.name} (ordered ${item.quantity})'
                                : '${item.actualQuantity} × ${item.name}',
                          ),
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
          if (_canCancel(order.status))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _cancelOrder(context, appState),
                child: const Text('Cancel order'),
              ),
            ),
          if (order.status.isActive)
            OutlinedButton(
              onPressed: () => _raiseIssue(context, appState),
              child: const Text('Report an issue with this order'),
            ),
        ],
      ),
    );
  }

  /// Cancelling only makes sense before a driver has physically collected
  /// the items — once picked up, someone already has the bag in hand.
  bool _canCancel(OrderStatus status) =>
      status == OrderStatus.pending || status == OrderStatus.accepted || status == OrderStatus.pickupAssigned;

  void _cancelOrder(BuildContext context, AppState appState) {
    CancellationReason selected = CancellationReason.delay;
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Cancel order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you cancelling?'),
              for (final reason in CancellationReason.values)
                RadioListTile<CancellationReason>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: reason,
                  groupValue: selected,
                  title: Text(reason.label),
                  onChanged: (v) => setState(() => selected = v ?? selected),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Anything else? (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep order')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final notes = notesController.text.trim();
                final reasonText = notes.isEmpty ? selected.label : '${selected.label} — $notes';
                appState.cancelOrder(orderId, reasonText, category: selected, cancelledByRole: 'customer');
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order cancelled.')),
                );
              },
              child: const Text('Cancel order'),
            ),
          ],
        ),
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
