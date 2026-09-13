import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import 'schedule_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.partnerId, required this.quantities});

  final String partnerId;
  final Map<String, int> quantities;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = Map.of(widget.quantities);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partner = appState.partnerById(widget.partnerId);
    final items = partner.catalog.where((c) => (_quantities[c.id] ?? 0) > 0).toList();
    final subtotal = items.fold<double>(0, (sum, c) => sum + c.price * (_quantities[c.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('${item.serviceType.label} • ${formatCurrency(item.price)} each'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() {
                            final q = (_quantities[item.id] ?? 0) - 1;
                            _quantities[item.id] = q < 0 ? 0 : q;
                          }),
                        ),
                        Text('${_quantities[item.id] ?? 0}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _quantities[item.id] = (_quantities[item.id] ?? 0) + 1),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items subtotal', style: Theme.of(context).textTheme.titleMedium),
                    Text(formatCurrency(subtotal), style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivery fee and payment are confirmed on the next step.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    final orderItems = items
                        .map(
                          (c) => OrderItem(
                            catalogItemId: c.id,
                            name: c.name,
                            serviceType: c.serviceType,
                            quantity: _quantities[c.id] ?? 0,
                            unitPrice: c.price,
                          ),
                        )
                        .toList();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScheduleScreen(partnerId: partner.id, items: orderItems),
                      ),
                    );
                  },
                  child: const Text('Schedule pickup'),
                ),
              ),
            ),
    );
  }
}
