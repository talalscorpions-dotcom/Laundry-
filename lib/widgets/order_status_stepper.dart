import 'package:flutter/material.dart';

import '../models/enums.dart';

/// The subset (and order) of statuses shown to a customer as a linear
/// journey. `pickupAssigned`/`deliveryAssigned` fold into the neighbouring
/// step below so the stepper doesn't grow every time a driver is assigned.
const List<OrderStatus> _steps = [
  OrderStatus.pending,
  OrderStatus.accepted,
  OrderStatus.pickedUp,
  OrderStatus.washing,
  OrderStatus.ironing,
  OrderStatus.readyForDelivery,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

int _stepIndexFor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.accepted:
    case OrderStatus.pickupAssigned:
      return 1;
    case OrderStatus.pickedUp:
      return 2;
    case OrderStatus.washing:
      return 3;
    case OrderStatus.ironing:
      return 4;
    case OrderStatus.readyForDelivery:
    case OrderStatus.deliveryAssigned:
      return 5;
    case OrderStatus.outForDelivery:
      return 6;
    case OrderStatus.delivered:
      return 7;
    case OrderStatus.cancelled:
      return -1;
  }
}

class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stepIndexFor(status);
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i].label,
            done: i < currentIndex,
            active: i == currentIndex,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done, required this.active, required this.isLast});

  final String label;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : (active ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                color: color,
                size: 20,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color.withOpacity(done ? 1 : 0.3)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Theme.of(context).colorScheme.primary : Colors.black87,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
