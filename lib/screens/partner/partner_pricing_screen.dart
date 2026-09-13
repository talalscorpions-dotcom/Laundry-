import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/catalog.dart';
import '../../models/enums.dart';
import '../../utils/formatters.dart';

/// Lets a partner update per-item pricing on their own catalog.
class PartnerPricingScreen extends StatelessWidget {
  const PartnerPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final partner = appState.partnerById(appState.currentPartnerId);

    final Map<ServiceType, List<CatalogItem>> grouped = {};
    for (final item in partner.catalog) {
      grouped.putIfAbsent(item.serviceType, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Service pricing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in grouped.entries) ...[
            Text(entry.key.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in entry.value)
              Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(formatCurrency(item.price)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editPrice(context, appState, partner.id, item),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _editPrice(BuildContext context, AppState appState, String partnerId, CatalogItem item) {
    final controller = TextEditingController(text: item.price.toStringAsFixed(3));
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update price • ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'OMR '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                appState.updateCatalogPrice(partnerId, item.id, value);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
