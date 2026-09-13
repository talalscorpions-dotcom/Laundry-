import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/dispute.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/user_models.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import 'mock_data.dart';

/// Single source of truth for the whole demo: the "backend" every screen
/// (customer, partner, driver, admin) reads from and writes through. A real
/// build would split this into API-backed repositories per bounded context
/// (orders, catalog, users) behind the same method signatures.
class AppState extends ChangeNotifier {
  AppState({
    PaymentGateway? paymentGateway,
    LocationTracker? locationTracker,
    NotificationService? notificationService,
  })  : paymentGateway = paymentGateway ?? MockPaymentGateway(),
        locationTracker = locationTracker ?? SimulatedLocationTracker(),
        notificationService = notificationService ?? InMemoryNotificationService();

  final PaymentGateway paymentGateway;
  final LocationTracker locationTracker;
  final NotificationService notificationService;

  UserRole? currentRole;

  // The demo signs in as a fixed persona per role rather than building a
  // full auth flow — swap for real session/user lookups when wiring auth.
  final String currentDriverId = MockData.drivers.first.id;
  final String currentPartnerId = MockData.partners.first.id;

  final Customer customer = MockData.customer;
  final List<LaundryPartner> partners = List.of(MockData.partners);
  final List<Driver> drivers = List.of(MockData.drivers);
  final List<LaundryOrder> orders = [];
  final List<Dispute> disputes = [];

  int _orderSeq = 1000;

  void signInAs(UserRole role) {
    currentRole = role;
    notifyListeners();
  }

  void signOut() {
    currentRole = null;
    notifyListeners();
  }

  LaundryPartner partnerById(String id) => partners.firstWhere((p) => p.id == id);

  Driver? driverById(String id) {
    for (final driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  List<LaundryOrder> ordersForPartner(String partnerId) {
    final list = orders.where((o) => o.partnerId == partnerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<LaundryOrder> ordersForCustomer(String customerId) {
    final list = orders.where((o) => o.customerId == customerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<LaundryOrder> ordersForDriver(String driverId) {
    final list = orders.where((o) => o.pickupDriverId == driverId || o.deliveryDriverId == driverId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Places a new order: snapshots the partner's current commission rate,
  /// charges the customer through [paymentGateway] (cash-on-delivery is
  /// deferred), and notifies the partner of the new job.
  Future<LaundryOrder> placeOrder({
    required String partnerId,
    required List<OrderItem> items,
    required Address pickupAddress,
    required Address deliveryAddress,
    required TimeSlot pickupSlot,
    required PaymentMethod paymentMethod,
  }) async {
    final partner = partnerById(partnerId);
    final order = LaundryOrder(
      id: 'ORD-${_orderSeq++}',
      customerId: customer.id,
      partnerId: partnerId,
      items: items,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupSlot: pickupSlot,
      paymentMethod: paymentMethod,
      commissionRate: partner.commissionRate,
    );
    order.logEvent('Order placed by customer, awaiting ${partner.name} confirmation.');

    final payment = await paymentGateway.charge(orderId: order.id, amount: order.total, method: paymentMethod);
    order.paymentStatus = !payment.success
        ? PaymentStatus.failed
        : (paymentMethod == PaymentMethod.cashOnDelivery ? PaymentStatus.pending : PaymentStatus.paid);

    orders.add(order);
    notificationService.notify(partnerId, 'New order ${order.id} received (${items.length} item lines).');
    notifyListeners();
    return order;
  }

  void acceptOrder(String orderId) {
    _mutate(orderId, (o) {
      o.status = OrderStatus.accepted;
      o.logEvent('Partner accepted the order.');
    });
    notificationService.notify(customer.id, 'Your order $orderId has been accepted.');
  }

  void assignPickupDriver(String orderId, String driverId) {
    _mutate(orderId, (o) {
      o.pickupDriverId = driverId;
      o.status = OrderStatus.pickupAssigned;
      o.logEvent('${driverById(driverId)?.name ?? driverId} assigned for pickup.');
    });
  }

  void markPickedUp(String orderId) {
    _mutate(orderId, (o) {
      o.status = OrderStatus.pickedUp;
      o.logEvent('Items picked up from customer.');
    });
  }

  void advanceProcessing(String orderId, OrderStatus next) {
    _mutate(orderId, (o) {
      o.status = next;
      o.logEvent('Status updated to ${next.label}.');
    });
  }

  void assignDeliveryDriver(String orderId, String driverId) {
    _mutate(orderId, (o) {
      o.deliveryDriverId = driverId;
      o.status = OrderStatus.deliveryAssigned;
      o.logEvent('${driverById(driverId)?.name ?? driverId} assigned for delivery.');
    });
  }

  void markOutForDelivery(String orderId) {
    _mutate(orderId, (o) {
      o.status = OrderStatus.outForDelivery;
      o.logEvent('Out for delivery.');
    });
  }

  void markDelivered(String orderId) {
    _mutate(orderId, (o) {
      o.status = OrderStatus.delivered;
      if (o.paymentMethod == PaymentMethod.cashOnDelivery) {
        o.paymentStatus = PaymentStatus.paid;
      }
      o.logEvent('Delivered to customer.');
    });
  }

  void cancelOrder(String orderId, String reason) {
    _mutate(orderId, (o) {
      o.status = OrderStatus.cancelled;
      o.logEvent('Order cancelled: $reason');
    });
  }

  void raiseDispute({required String orderId, required String raisedByRole, required String reason}) {
    disputes.add(Dispute(id: 'DSP-${disputes.length + 1}', orderId: orderId, raisedByRole: raisedByRole, reason: reason));
    notifyListeners();
  }

  void resolveDispute(String disputeId, String resolutionNotes) {
    final dispute = disputes.firstWhere((d) => d.id == disputeId);
    dispute.status = DisputeStatus.resolved;
    dispute.resolutionNotes = resolutionNotes;
    notifyListeners();
  }

  void updateCatalogPrice(String partnerId, String itemId, double newPrice) {
    final partner = partnerById(partnerId);
    final index = partner.catalog.indexWhere((c) => c.id == itemId);
    if (index != -1) {
      partner.catalog[index] = partner.catalog[index].copyWith(price: newPrice);
      notifyListeners();
    }
  }

  // ---- Admin analytics ----

  double get totalGmv {
    return orders.where((o) => o.status != OrderStatus.cancelled).fold(0, (s, o) => s + o.total);
  }

  double get totalCommission {
    return orders.where((o) => o.status != OrderStatus.cancelled).fold(0, (s, o) => s + o.commissionAmount);
  }

  int get activeOrderCount => orders.where((o) => o.status.isActive).length;

  int get completedOrderCount => orders.where((o) => o.status == OrderStatus.delivered).length;

  void _mutate(String orderId, void Function(LaundryOrder order) mutate) {
    final order = orders.firstWhere((o) => o.id == orderId);
    mutate(order);
    notifyListeners();
  }
}
