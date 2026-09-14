import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../widgets/status_chip.dart';

/// The hub staff's per-order workspace — the one screen that walks an order
/// through `atHub` -> `inspecting` -> `processing` -> `qualityCheck` ->
/// `readyForDelivery`, mirroring the internal pipeline in
/// `OrderStatus`'s doc comment.
class StaffOrderDetailScreen extends StatefulWidget {
  const StaffOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<StaffOrderDetailScreen> createState() => _StaffOrderDetailScreenState();
}

class _StaffOrderDetailScreenState extends State<StaffOrderDetailScreen> {
  late final Map<String, TextEditingController> _quantityControllers;
  final _notesController = TextEditingController();
  final _qcNotesController = TextEditingController();
  final List<String> _photoNames = [];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == widget.orderId);
    _quantityControllers = {
      for (final item in order.items) item.catalogItemId: TextEditingController(text: '${item.actualQuantity}'),
    };
  }

  @override
  void dispose() {
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    _qcNotesController.dispose();
    super.dispose();
  }

  Future<void> _attachPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _photoNames.add(result.files.single.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orders.firstWhere((o) => o.id == widget.orderId);
    final partner = appState.partnerById(order.partnerId);

    return Scaffold(
      appBar: AppBar(title: Text(order.bagId ?? order.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(partner.name, style: Theme.of(context).textTheme.titleMedium),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('Order ${order.id}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ..._sectionFor(context, appState, order),
        ],
      ),
    );
  }

  List<Widget> _sectionFor(BuildContext context, AppState appState, LaundryOrder order) {
    switch (order.status) {
      case OrderStatus.atHub:
        return [
          const Text('Bag received from the pickup driver. Start inspection when ready.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => appState.startInspection(order.id),
            child: const Text('Start inspection'),
          ),
        ];
      case OrderStatus.inspecting:
        return _inspectionForm(context, appState, order);
      case OrderStatus.processing:
        return _processingSection(context, appState, order);
      case OrderStatus.qualityCheck:
        return _qualityCheckSection(context, appState, order);
      case OrderStatus.readyForDelivery:
      case OrderStatus.deliveryAssigned:
      case OrderStatus.outForDelivery:
      case OrderStatus.delivered:
        return const [Text('This order has left the hub — nothing left for staff to do here.')];
      case OrderStatus.pending:
      case OrderStatus.accepted:
      case OrderStatus.pickupAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.cancelled:
        return const [Text('This order hasn\'t reached the hub yet.')];
    }
  }

  List<Widget> _inspectionForm(BuildContext context, AppState appState, LaundryOrder order) {
    return [
      Text('Verify item counts', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final item in order.items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text('${item.name} (${item.serviceType.label}) — customer said ${item.quantity}')),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _quantityControllers[item.catalogItemId],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Inspection notes (damage, stains, missing items...)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _attachPhoto,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Attach photo (demo)'),
      ),
      if (_photoNames.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Attached: ${_photoNames.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
        ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () {
          final actualQuantities = <String, int>{
            for (final entry in _quantityControllers.entries) entry.key: int.tryParse(entry.value.text.trim()) ?? 0,
          };
          appState.recordInspection(
            order.id,
            actualQuantities: actualQuantities,
            notes: _notesController.text.trim().isEmpty ? const [] : [_notesController.text.trim()],
            photoNames: _photoNames,
          );
        },
        child: const Text('Complete inspection & start processing'),
      ),
    ];
  }

  List<Widget> _processingSection(BuildContext context, AppState appState, LaundryOrder order) {
    final stage = order.processingStage ?? ProcessingStage.received;
    return [
      Text('Processing pipeline', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ProcessingStage.values)
            Chip(
              label: Text(s.label),
              backgroundColor: s == stage
                  ? Theme.of(context).colorScheme.primaryContainer
                  : (s.index < stage.index ? Colors.green.withOpacity(0.15) : null),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (stage.next != null)
        ElevatedButton(
          onPressed: () => appState.advanceProcessingStage(order.id),
          child: Text('Advance to ${stage.next!.label}'),
        )
      else
        ElevatedButton(
          onPressed: () => appState.completeProcessing(order.id),
          child: const Text('Complete processing — send to quality check'),
        ),
    ];
  }

  List<Widget> _qualityCheckSection(BuildContext context, AppState appState, LaundryOrder order) {
    return [
      Text('Quality check', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text('Confirm every item is clean, undamaged, and matches the order before it goes out for delivery.'),
      const SizedBox(height: 12),
      TextField(
        controller: _qcNotesController,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'QC notes (optional)', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => appState.completeQualityCheck(order.id, passed: false, notes: _qcNotesController.text),
              child: const Text('Fail — send back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => appState.completeQualityCheck(order.id, passed: true, notes: _qcNotesController.text),
              child: const Text('Pass QC'),
            ),
          ),
        ],
      ),
    ];
  }
}
