// Unit tests for the driver weekly-availability / slot-capacity logic in
// AppState: a slot should read as fully booked once every rostered driver
// for it already has an order occupying that same window, and the partner's
// pickup-assignment list should track the same rule.

import 'package:flutter_test/flutter_test.dart';

import 'package:laundrygo/data/app_state.dart';
import 'package:laundrygo/models/address.dart';
import 'package:laundrygo/models/enums.dart';
import 'package:laundrygo/models/order.dart';
import 'package:laundrygo/utils/scheduling.dart';

/// The next date (today included) that falls on [weekday]
/// (`DateTime.monday`..`DateTime.sunday`), so tests are deterministic
/// regardless of what day they happen to run on.
DateTime _nextDateForWeekday(int weekday) {
  var day = DateTime.now();
  day = DateTime(day.year, day.month, day.day);
  while (day.weekday != weekday) {
    day = day.add(const Duration(days: 1));
  }
  return day;
}

const _address = Address(
  id: 'addr-test',
  label: 'Home',
  line1: 'Test street',
  city: 'Muscat',
  location: GeoPoint(23.588, 58.407),
);

LaundryOrder _pendingOrderFor(TimeSlot slot, {required String id}) {
  return LaundryOrder(
    id: id,
    customerId: 'cust-test',
    partnerId: 'partner-1',
    items: const [],
    pickupAddress: _address,
    deliveryAddress: _address,
    pickupSlot: slot,
    paymentMethod: PaymentMethod.card,
    commissionRate: 0.2,
  );
}

void main() {
  late AppState appState;
  late TimeSlot slot;

  setUp(() {
    appState = AppState();
    final monday = _nextDateForWeekday(DateTime.monday);
    slot = slotsForDay(monday).first; // the 9-11 window
  });

  test('a slot with rostered drivers and no bookings is not fully booked', () {
    // Both seeded demo drivers default to full weekly availability.
    expect(appState.isSlotFullyBooked(slot), isFalse);
    expect(appState.driversAvailableForSlot(slot).length, 2);
  });

  test('un-rostering every driver for a slot makes it fully booked', () {
    for (final driver in appState.drivers) {
      appState.setDriverSlotAvailability(
        driverId: driver.id,
        weekday: slot.start.weekday,
        slotIndex: 0,
        available: false,
      );
    }

    expect(appState.isSlotFullyBooked(slot), isTrue);
    expect(appState.driversAvailableForSlot(slot), isEmpty);
  });

  test('re-rostering one driver makes the slot bookable again, for just that driver', () {
    for (final driver in appState.drivers) {
      appState.setDriverSlotAvailability(
        driverId: driver.id,
        weekday: slot.start.weekday,
        slotIndex: 0,
        available: false,
      );
    }
    appState.setDriverSlotAvailability(
      driverId: appState.drivers.first.id,
      weekday: slot.start.weekday,
      slotIndex: 0,
      available: true,
    );

    expect(appState.isSlotFullyBooked(slot), isFalse);
    final available = appState.driversAvailableForSlot(slot);
    expect(available.length, 1);
    expect(available.single.id, appState.drivers.first.id);
  });

  test('a slot fills up once bookings reach the number of rostered drivers', () {
    expect(appState.drivers.length, 2);

    appState.orders.add(_pendingOrderFor(slot, id: 'ORD-A'));
    expect(appState.isSlotFullyBooked(slot), isFalse); // 1 booking, 2 drivers

    appState.orders.add(_pendingOrderFor(slot, id: 'ORD-B'));
    expect(appState.isSlotFullyBooked(slot), isTrue); // 2 bookings, 2 drivers
  });

  test('a cancelled order frees up the slot it occupied', () {
    appState.orders.add(_pendingOrderFor(slot, id: 'ORD-A'));
    appState.orders.add(_pendingOrderFor(slot, id: 'ORD-B'));
    expect(appState.isSlotFullyBooked(slot), isTrue);

    appState.cancelOrder('ORD-B', 'test cancellation');

    expect(appState.isSlotFullyBooked(slot), isFalse);
  });

  test('a driver already assigned to a pickup in this slot is excluded from the assignable list', () {
    final order = _pendingOrderFor(slot, id: 'ORD-A');
    appState.orders.add(order);
    appState.assignPickupDriver('ORD-A', appState.drivers.first.id);

    final available = appState.driversAvailableForSlot(slot);
    expect(available.any((d) => d.id == appState.drivers.first.id), isFalse);
    expect(available.length, 1);
  });
}
