import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/enums.dart';

/// "Resolve disputes" — every issue a customer/partner/driver raises lands
/// here for the admin to close out with resolution notes.
class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final disputes = List.of(appState.disputes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: disputes.isEmpty
          ? const Center(child: Text('No disputes raised.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: disputes.length,
              itemBuilder: (context, index) {
                final dispute = disputes[index];
                return Card(
                  child: ListTile(
                    title: Text('${dispute.orderId} • raised by ${dispute.raisedByRole}'),
                    subtitle: Text(
                      dispute.status == DisputeStatus.resolved
                          ? 'Resolved: ${dispute.resolutionNotes ?? ''}'
                          : dispute.reason,
                    ),
                    trailing: dispute.status == DisputeStatus.open
                        ? TextButton(
                            onPressed: () => _resolve(context, appState, dispute.id),
                            child: const Text('Resolve'),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }

  void _resolve(BuildContext context, AppState appState, String disputeId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve dispute'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Resolution notes')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              appState.resolveDispute(
                disputeId,
                controller.text.trim().isEmpty ? 'Resolved by admin' : controller.text.trim(),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
