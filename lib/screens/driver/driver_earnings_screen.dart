import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';

/// Flat fee paid per completed pickup or delivery leg. A real system would
/// price this per distance/time via the same pricing engine that computes
/// [kDeliveryFee].
const double _feePerLeg = 1.200;

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myOrders = appState.ordersForDriver(appState.currentDriverId);
    final completedLegs = myOrders.where((o) {
      final pickupLegDone =
          o.pickupDriverId == appState.currentDriverId && o.status != OrderStatus.pending && o.status != OrderStatus.accepted;
      final deliveryLegDone = o.deliveryDriverId == appState.currentDriverId && o.status == OrderStatus.delivered;
      return pickupLegDone || deliveryLegDone;
    }).length;
    final earnings = completedLegs * _feePerLeg;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated earnings', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(formatCurrency(earnings), style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('$completedLegs completed legs • ${formatCurrency(_feePerLeg)} each'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final order in myOrders)
            Card(
              child: ListTile(title: Text(order.id), subtitle: Text(order.status.label)),
            ),
        ],
      ),
    );
  }
}
