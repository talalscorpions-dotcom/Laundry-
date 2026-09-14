// Unit tests for the admin Analytics screen's reporting methods on
// AppState: the order funnel (received/picked up/delivered), revenue,
// partner performance, driver pickup-time performance, and cancellation
// reporting, all filtered by ReportPeriod.

import 'package:flutter_test/flutter_test.dart';

import 'package:laundrygo/data/app_state.dart';
import 'package:laundrygo/models/address.dart';
import 'package:laundrygo/models/enums.dart';
import 'package:laundrygo/models/order.dart';
import 'package:laundrygo/utils/analytics.dart';

const _address = Address(
  id: 'addr-test',
  label: 'Home',
  line1: 'Test street',
  city: 'Muscat',
  location: GeoPoint(23.588, 58.407),
);

LaundryOrder _order(String id, {String partnerId = 'partner-1', DateTime? createdAt}) {
  return LaundryOrder(
    id: id,
    customerId: 'cust-1',
    partnerId: partnerId,
    items: [
      OrderItem(catalogItemId: 'p1-shirt-wf', name: 'Shirt', serviceType: ServiceType.washFold, quantity: 1, unitPrice: 1.0),
    ],
    pickupAddress: _address,
    deliveryAddress: _address,
    pickupSlot: TimeSlot(DateTime(2030, 1, 7, 9), DateTime(2030, 1, 7, 11)),
    paymentMethod: PaymentMethod.card,
    commissionRate: 0.2,
    createdAt: createdAt,
  );
}

void main() {
  late AppState appState;

  setUp(() {
    appState = AppState();
  });

  test('order funnel counts received, picked up, and delivered separately', () {
    final a = _order('ORD-A')..pickedUpAt = DateTime.now();
    final b = _order('ORD-B'); // received but never picked up
    final c = _order('ORD-C')
      ..pickedUpAt = DateTime.now()
      ..status = OrderStatus.delivered;
    appState.orders.addAll([a, b, c]);

    expect(appState.receivedCountFor(ReportPeriod.allTime), 3);
    expect(appState.pickedUpCountFor(ReportPeriod.allTime), 2);
    expect(appState.deliveredCountFor(ReportPeriod.allTime), 1);
  });

  test('revenue and commission exclude cancelled orders', () {
    final active = _order('ORD-A'); // subtotal 1.0 + delivery 0.5 = 1.5
    final cancelled = _order('ORD-B')..status = OrderStatus.cancelled;
    appState.orders.addAll([active, cancelled]);

    expect(appState.revenueFor(ReportPeriod.allTime), closeTo(1.5, 0.0001));
    expect(appState.commissionFor(ReportPeriod.allTime), closeTo(0.2, 0.0001)); // 20% of 1.0
  });

  test('ReportPeriod.today excludes orders created before today', () {
    final today = _order('ORD-TODAY');
    final lastYear = _order('ORD-OLD', createdAt: DateTime.now().subtract(const Duration(days: 400)));
    appState.orders.addAll([today, lastYear]);

    expect(appState.receivedCountFor(ReportPeriod.today), 1);
    expect(appState.receivedCountFor(ReportPeriod.allTime), 2);
  });

  test('orderCountByPartner groups orders per partner', () {
    appState.orders.addAll([
      _order('ORD-A', partnerId: 'partner-1'),
      _order('ORD-B', partnerId: 'partner-1'),
      _order('ORD-C', partnerId: 'partner-2'),
    ]);

    final counts = appState.orderCountByPartner(ReportPeriod.allTime);
    expect(counts['partner-1'], 2);
    expect(counts['partner-2'], 1);
  });

  test('driver pickup stats compute average time and flag slow pickups', () {
    final driverId = appState.drivers.first.id;
    final now = DateTime.now();

    final fast = _order('ORD-FAST')
      ..pickupDriverId = driverId
      ..pickupAssignedAt = now
      ..pickedUpAt = now.add(const Duration(minutes: 5));
    final slow = _order('ORD-SLOW')
      ..pickupDriverId = driverId
      ..pickupAssignedAt = now
      ..pickedUpAt = now.add(const Duration(minutes: 25));
    appState.orders.addAll([fast, slow]);

    final avg = appState.averagePickupDuration(ReportPeriod.allTime, driverId: driverId);
    expect(avg, const Duration(minutes: 15));
    expect(appState.slowPickupCount(ReportPeriod.allTime, driverId: driverId), 1);

    final stats = appState.driverPickupStats(ReportPeriod.allTime)[driverId]!;
    expect(stats.pickupCount, 2);
    expect(stats.slowCount, 1);
  });

  test('cancelOrder records a structured reason the analytics screen can count', () {
    appState.orders.add(_order('ORD-A'));

    appState.cancelOrder('ORD-A', 'Order was taking too long', category: CancellationReason.delay,
        cancelledByRole: 'customer');

    expect(appState.cancelledCountFor(ReportPeriod.allTime), 1);
    expect(appState.cancelledDueToDelayCountFor(ReportPeriod.allTime), 1);

    final order = appState.orders.single;
    expect(order.status, OrderStatus.cancelled);
    expect(order.cancellationReason, CancellationReason.delay);
    expect(order.cancelledByRole, 'customer');
    expect(order.cancelledAt, isNotNull);
  });

  test('cancellations for another reason do not count as delay-cancellations', () {
    appState.orders.add(_order('ORD-A'));
    appState.cancelOrder('ORD-A', 'Changed my mind', category: CancellationReason.changedMind);

    expect(appState.cancelledCountFor(ReportPeriod.allTime), 1);
    expect(appState.cancelledDueToDelayCountFor(ReportPeriod.allTime), 0);
  });
}
