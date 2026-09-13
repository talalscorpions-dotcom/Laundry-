import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/catalog.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';
import 'cart_screen.dart';

/// The itemized catalog for one laundry partner — grouped by service
/// (wash & fold, dry cleaning, ironing) with per-item pricing and a quantity
/// stepper, matching the "itemized catalog" requirement.
class PartnerCatalogScreen extends StatefulWidget {
  const PartnerCatalogScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<PartnerCatalogScreen> createState() => _PartnerCatalogScreenState();
}

class _PartnerCatalogScreenState extends State<PartnerCatalogScreen> {
  final Map<String, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partner = appState.partnerById(widget.partnerId);

    final Map<ServiceType, List<CatalogItem>> grouped = {};
    for (final item in partner.catalog) {
      grouped.putIfAbsent(item.serviceType, () => []).add(item);
    }

    final itemCount = _quantities.values.fold(0, (a, b) => a + b);
    final total = partner.catalog.fold<double>(0, (sum, item) => sum + item.price * (_quantities[item.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(partner.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            '${partner.area} • ★ ${partner.rating.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final entry in grouped.entries) ...[
            Text(entry.key.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in entry.value)
              _CatalogItemRow(
                item: item,
                quantity: _quantities[item.id] ?? 0,
                onChanged: (q) => setState(() => _quantities[item.id] = q),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottomNavigationBar: itemCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CartScreen(partnerId: partner.id, quantities: Map.of(_quantities)),
                    ),
                  ),
                  child: Text(
                    'View cart • $itemCount item${itemCount == 1 ? '' : 's'} • ${formatCurrency(total)}',
                  ),
                ),
              ),
            ),
    );
  }
}

class _CatalogItemRow extends StatelessWidget {
  const _CatalogItemRow({required this.item, required this.quantity, required this.onChanged});

  final CatalogItem item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                Text(formatCurrency(item.price), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(width: 24, child: Text('$quantity', textAlign: TextAlign.center)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}
