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
///
/// Edits build up in a local draft and only take effect once the driver
/// taps "Confirm and save" — nothing is written to `AppState` chip by chip.
class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  late Map<int, Set<int>> _draft;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final driver = appState.driverById(appState.currentDriverId)!;
    // A deep copy: further edits build up here, untouched by (and not
    // overwriting) whatever's actually saved until "Confirm" is tapped.
    _draft = {for (final entry in driver.weeklyAvailability.entries) entry.key: Set.of(entry.value)};
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final driver = appState.driverById(appState.currentDriverId)!;

    return Scaffold(
      appBar: AppBar(title: const Text('My weekly schedule')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            "Choose the hours you're available for pickups each week, between "
            '9 AM and 9 PM, then confirm to save. Customers can only book a '
            'time slot when a driver is rostered for it.',
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
                    selected: _draft[entry.key]?.contains(i) ?? false,
                    onSelected: (selected) => setState(() {
                      final daySlots = _draft.putIfAbsent(entry.key, () => {});
                      if (selected) {
                        daySlots.add(i);
                      } else {
                        daySlots.remove(i);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm and save schedule'),
            onPressed: () {
              appState.setDriverWeeklyAvailability(driver.id, _draft);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Weekly schedule saved.')),
              );
            },
          ),
        ),
      ),
    );
  }
}
