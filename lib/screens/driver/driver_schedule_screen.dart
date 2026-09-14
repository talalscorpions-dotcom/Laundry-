import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../utils/scheduling.dart';

const Map<int, String> _dayNames = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// "Receive pickup tasks" starts here: a driver rosters the hours they work
/// each week (9 AM - 9 PM, in the same six windows customers pick a pickup
/// slot from). `AppState.isSlotFullyBooked` and `driversAvailableForSlot`
/// read this to tell a customer/partner when a slot has no rostered driver
/// left.
class DriverScheduleScreen extends StatelessWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final driver = appState.driverById(appState.currentDriverId)!;

    return Scaffold(
      appBar: AppBar(title: const Text('My weekly schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Choose the hours you're available for pickups each week, between "
            '9 AM and 9 PM. Customers can only book a time slot when a driver '
            'is rostered for it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final entry in _dayNames.entries) ...[
            Text(entry.value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < kSlotWindows.length; i++)
                  FilterChip(
                    label: Text(slotWindowLabel(i)),
                    selected: driver.isAvailableAt(entry.key, i),
                    onSelected: (selected) => appState.setDriverSlotAvailability(
                      driverId: driver.id,
                      weekday: entry.key,
                      slotIndex: i,
                      available: selected,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
