// Unit tests for the Order+Bag+Item+Process pipeline added to AppState:
// hub drop-off (bag ID), staff inspection (item recount changes billing),
// the internal processing stages, quality check pass/fail, and OTP-gated
// delivery confirmation.

import 'package:flutter_test/flutter_test.dart';

import 'package:laundrygo/data/app_state.dart';
import 'package:laundrygo/models/address.dart';
import 'package:laundrygo/models/enums.dart';
import 'package:laundrygo/models/order.dart';

const _address = Address(
  id: 'addr-test',
  label: 'Home',
  line1: 'Test street',
  city: 'Muscat',
  location: GeoPoint(23.588, 58.407),
);

void main() {
  late AppState appState;
  late LaundryOrder order;

  setUp(() {
    appState = AppState();
    order = LaundryOrder(
      id: 'ORD-TEST',
      customerId: 'cust-1',
      partnerId: 'partner-1',
      items: [
        OrderItem(catalogItemId: 'p1-shirt-wf', name: 'Shirt', serviceType: ServiceType.washFold, quantity: 3, unitPrice: 1.0),
      ],
      pickupAddress: _address,
      deliveryAddress: _address,
      pickupSlot: TimeSlot(DateTime(2030, 1, 7, 9), DateTime(2030, 1, 7, 11)),
      paymentMethod: PaymentMethod.cashOnDelivery,
      commissionRate: 0.2,
      status: OrderStatus.pickedUp,
    );
    appState.orders.add(order);
  });

  test('dropping off at the hub assigns a bag ID and moves to atHub', () {
    appState.markDroppedOffAtHub(order.id);
    expect(order.status, OrderStatus.atHub);
    expect(order.bagId, isNotNull);
  });

  test('inspection can adjust an item count, which changes billed total', () {
    appState.markDroppedOffAtHub(order.id);
    appState.startInspection(order.id);
    expect(order.status, OrderStatus.inspecting);

    expect(order.items.single.lineTotal, 3.0); // 3 x 1.0 before inspection

    appState.recordInspection(
      order.id,
      actualQuantities: {'p1-shirt-wf': 2},
      notes: ['1 shirt was already in the bag at drop-off, not this customer\'s'],
    );

    expect(order.status, OrderStatus.processing);
    expect(order.processingStage, ProcessingStage.received);
    expect(order.items.single.actualQuantity, 2);
    expect(order.items.single.quantityAdjustedByStaff, isTrue);
    expect(order.items.single.lineTotal, 2.0); // billing follows actualQuantity
    expect(order.inspectionNotes, isNotEmpty);
  });

  test('processing stage advances one step at a time to packing, then completes to QC', () {
    order.status = OrderStatus.processing;
    order.processingStage = ProcessingStage.received;

    for (final expected in [
      ProcessingStage.sorting,
      ProcessingStage.washing,
      ProcessingStage.drying,
      ProcessingStage.ironing,
      ProcessingStage.folding,
      ProcessingStage.packing,
    ]) {
      appState.advanceProcessingStage(order.id);
      expect(order.processingStage, expected);
    }

    // Already at the last stage: advancing again is a no-op.
    appState.advanceProcessingStage(order.id);
    expect(order.processingStage, ProcessingStage.packing);

    appState.completeProcessing(order.id);
    expect(order.status, OrderStatus.qualityCheck);
    expect(order.processingStage, isNull);
  });

  test('a failed quality check sends the order back to folding, not all the way to washing', () {
    order.status = OrderStatus.qualityCheck;
    appState.completeQualityCheck(order.id, passed: false, notes: 'Collar still has a mark');

    expect(order.status, OrderStatus.processing);
    expect(order.processingStage, ProcessingStage.folding);
    expect(order.inspectionNotes.any((n) => n.contains('Collar')), isTrue);
  });

  test('a passed quality check makes the order ready for delivery', () {
    order.status = OrderStatus.qualityCheck;
    appState.completeQualityCheck(order.id, passed: true);
    expect(order.status, OrderStatus.readyForDelivery);
  });

  test('delivery requires the correct OTP; a wrong code changes nothing', () {
    order.status = OrderStatus.deliveryAssigned;
    appState.markOutForDelivery(order.id);
    final code = order.deliveryOtp;
    expect(code, isNotNull);
    expect(code!.length, 4);

    final wrongAttempt = appState.confirmDelivery(order.id, '0000');
    expect(wrongAttempt, isFalse);
    expect(order.status, OrderStatus.outForDelivery);

    final rightAttempt = appState.confirmDelivery(order.id, code);
    expect(rightAttempt, isTrue);
    expect(order.status, OrderStatus.delivered);
    expect(order.paymentStatus, PaymentStatus.paid); // cash on delivery settles on delivery
  });
}
