import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../utils/scheduling.dart';
import 'address_selector.dart';
import 'checkout_payment_screen.dart';

/// "Smart scheduling" — pick a pickup address, a day, a locked time window,
/// and (optionally) a different delivery address.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.partnerId, required this.items});

  final String partnerId;
  final List<OrderItem> items;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedDay;
  TimeSlot? _selectedSlot;
  Address? _pickupAddress;
  Address? _deliveryAddress;
  bool _sameAddress = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = nextDays(4).first;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _pickupAddress ??= appState.currentCustomer.addresses.first;
    _deliveryAddress ??= appState.currentCustomer.addresses.first;
    final days = nextDays(4);
    final slots = slotsForDay(_selectedDay);
    if (_selectedSlot != null && appState.isSlotFullyBooked(_selectedSlot!)) {
      // Someone else took the last rostered driver for it since it was picked.
      _selectedSlot = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule pickup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pickup address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AddressSelector(
            selected: _pickupAddress,
            onChanged: (address) => setState(() {
              _pickupAddress = address;
              if (_sameAddress) _deliveryAddress = address;
            }),
          ),
          const SizedBox(height: 16),
          Text('Pickup day', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final selected = day == _selectedDay;
                final dayFull = slotsForDay(day).every(appState.isSlotFullyBooked);
                return ChoiceChip(
                  label: Text('${weekdayLabel(day)} • ${monthDayLabel(day)}${dayFull ? ' (Full)' : ''}'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedDay = day;
                    _selectedSlot = null;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Pickup time window', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                ChoiceChip(
                  label: Text(
                    appState.isSlotFullyBooked(slot) ? '${slot.label} • Fully booked' : slot.label,
                  ),
                  selected: _selectedSlot?.start == slot.start,
                  onSelected: appState.isSlotFullyBooked(slot) ? null : (_) => setState(() => _selectedSlot = slot),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deliver back to the same address'),
            value: _sameAddress,
            onChanged: (v) => setState(() {
              _sameAddress = v;
              if (v) _deliveryAddress = _pickupAddress;
            }),
          ),
          if (!_sameAddress) ...[
            Text('Delivery address', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AddressSelector(
              selected: _deliveryAddress,
              onChanged: (address) => setState(() => _deliveryAddress = address),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedSlot == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CheckoutPaymentScreen(
                          partnerId: widget.partnerId,
                          items: widget.items,
                          pickupAddress: _pickupAddress!,
                          deliveryAddress: _sameAddress ? _pickupAddress! : _deliveryAddress!,
                          pickupSlot: _selectedSlot!,
                        ),
                      ),
                    ),
            child: const Text('Continue to payment'),
          ),
        ),
      ),
    );
  }
}
