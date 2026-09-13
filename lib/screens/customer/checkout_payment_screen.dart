import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/address.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import 'order_tracking_screen.dart';

/// "Secure payments" step — the customer picks a method (card, wallet, or
/// cash on delivery) and confirms the order. The actual charge goes through
/// [AppState.paymentGateway], an interface a real gateway plugs into.
class CheckoutPaymentScreen extends StatefulWidget {
  const CheckoutPaymentScreen({
    super.key,
    required this.partnerId,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupSlot,
  });

  final String partnerId;
  final List<OrderItem> items;
  final Address pickupAddress;
  final Address deliveryAddress;
  final TimeSlot pickupSlot;

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  PaymentMethod _method = PaymentMethod.card;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partner = appState.partnerById(widget.partnerId);
    final subtotal = widget.items.fold<double>(0, (s, i) => s + i.lineTotal);
    final total = subtotal + kDeliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Pickup: ${widget.pickupAddress.label} • ${widget.pickupSlot.label}'),
                  const SizedBox(height: 12),
                  for (final item in widget.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity} × ${item.name} (${item.serviceType.label})'),
                          Text(formatCurrency(item.lineTotal)),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Items subtotal'), Text(formatCurrency(subtotal))],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Delivery fee'), Text(formatCurrency(kDeliveryFee))],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: Theme.of(context).textTheme.titleMedium),
                      Text(formatCurrency(total), style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Payment method', style: Theme.of(context).textTheme.titleMedium),
          for (final method in PaymentMethod.values)
            RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              value: method,
              groupValue: _method,
              title: Text(method.label),
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _placing ? null : () => _placeOrder(appState),
            child: _placing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Place order • ${formatCurrency(total)}'),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(AppState appState) async {
    setState(() => _placing = true);
    final order = await appState.placeOrder(
      partnerId: widget.partnerId,
      items: widget.items,
      pickupAddress: widget.pickupAddress,
      deliveryAddress: widget.deliveryAddress,
      pickupSlot: widget.pickupSlot,
      paymentMethod: _method,
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
  }
}
