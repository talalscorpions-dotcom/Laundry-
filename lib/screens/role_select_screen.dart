import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/enums.dart';

/// Stand-in for real sign-in/sign-up. Picking a role here simulates "logging
/// in" as that side of the marketplace so every panel can be demoed from one
/// app without a backend.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.local_laundry_service, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('LaundryGo', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'On-demand laundry pickup & delivery — a marketplace connecting '
                'customers, laundry partners and drivers.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text('Continue as', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Customer'),
                onPressed: () => appState.signInAs(UserRole.customer),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Laundry Partner'),
                onPressed: () => appState.signInAs(UserRole.partner),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.two_wheeler_outlined),
                label: const Text('Driver'),
                onPressed: () => appState.signInAs(UserRole.driver),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin'),
                onPressed: () => appState.signInAs(UserRole.admin),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
