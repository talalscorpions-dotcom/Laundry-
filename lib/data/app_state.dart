import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/address.dart';
import '../models/dispute.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/user_models.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../utils/password_hash.dart';
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

  final List<Customer> customers = List.of(MockData.customers);
  final List<LaundryPartner> partners = List.of(MockData.partners);
  final List<Driver> drivers = List.of(MockData.drivers);
  final List<LaundryOrder> orders = [];
  final List<Dispute> disputes = [];
  final List<Account> _accounts = List.of(MockData.accounts);

  int _orderSeq = 1000;
  int _customerSeq = 1;
  int _partnerSeq = 1;
  int _driverSeq = 1;

  // ---- Auth / RBAC ----
  //
  // `currentAccount` is the whole session: it carries both *who* is signed
  // in and *which role* they're allowed to act as (`currentAccount.role`).
  // `routing/auth_middleware.dart` is the other half of the RBAC story — it
  // reads `currentRole` on every top-level navigation to decide whether a
  // route is reachable, so a signed-in driver can never land on `/admin`
  // even via a deep link, and a signed-out visitor can never land on a
  // role's shell at all.

  Account? currentAccount;

  UserRole? get currentRole => currentAccount?.role;

  /// The Customer/LaundryPartner/Driver record the signed-in account
  /// controls. Only valid while signed in as that role — the middleware
  /// guarantees these are only read from behind the matching shell.
  Customer get currentCustomer => customers.firstWhere((c) => c.id == currentAccount!.linkedId);

  String get currentPartnerId => currentAccount!.linkedId!;

  String get currentDriverId => currentAccount!.linkedId!;

  /// Registers a new Customer/Partner/Driver account (Admin accounts are
  /// not self-service — see the check below) and signs it in immediately.
  /// A real backend would hash the password server-side and email a
  /// verification link instead of trusting the client outright like this.
  AuthResult signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? area,
    String? vehicle,
    String? addressLine,
    String? city,
  }) {
    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (role == UserRole.admin) {
      return const AuthResult.failure('Admin accounts cannot self-register — contact an existing admin.');
    }
    if (trimmedName.isEmpty) {
      return const AuthResult.failure('Enter your name.');
    }
    if (!normalizedEmail.contains('@')) {
      return const AuthResult.failure('Enter a valid email address.');
    }
    if (password.length < 6) {
      return const AuthResult.failure('Password must be at least 6 characters.');
    }
    if (_accounts.any((a) => a.email == normalizedEmail)) {
      return const AuthResult.failure('An account with that email already exists.');
    }

    final String linkedId;
    switch (role) {
      case UserRole.customer:
        if ((addressLine ?? '').trim().isEmpty || (city ?? '').trim().isEmpty) {
          return const AuthResult.failure('Enter your pickup address and city.');
        }
        linkedId = 'cust-${_customerSeq++}-${DateTime.now().millisecondsSinceEpoch}';
        customers.add(Customer(
          id: linkedId,
          name: trimmedName,
          phone: (phone ?? '').trim(),
          addresses: [
            Address(
              id: '$linkedId-addr-1',
              label: 'Home',
              line1: addressLine!.trim(),
              city: city!.trim(),
              // Placeholder coordinates: a real signup flow would geocode
              // the entered address or let the customer drop a pin.
              location: const GeoPoint(23.588, 58.407),
            ),
          ],
        ));
        break;
      case UserRole.partner:
        if ((area ?? '').trim().isEmpty) {
          return const AuthResult.failure('Enter your shop\'s area.');
        }
        linkedId = 'partner-${_partnerSeq++}-${DateTime.now().millisecondsSinceEpoch}';
        partners.add(LaundryPartner(
          id: linkedId,
          name: trimmedName,
          area: area!.trim(),
          // Placeholder — a real onboarding flow would collect a pinned
          // shop location.
          location: const GeoPoint(23.588, 58.407),
          rating: 5.0,
          isOpen: true,
          commissionRate: 0.20,
          catalog: const [],
        ));
        break;
      case UserRole.driver:
        if ((vehicle ?? '').trim().isEmpty) {
          return const AuthResult.failure('Enter your vehicle details.');
        }
        linkedId = 'driver-${_driverSeq++}-${DateTime.now().millisecondsSinceEpoch}';
        drivers.add(Driver(
          id: linkedId,
          name: trimmedName,
          phone: (phone ?? '').trim(),
          vehicle: vehicle!.trim(),
          rating: 5.0,
          isAvailable: true,
          location: const GeoPoint(23.590, 58.410),
        ));
        break;
      case UserRole.admin:
        // Unreachable: guarded above.
        return const AuthResult.failure('Admin accounts cannot self-register — contact an existing admin.');
    }

    final account = Account(
      id: 'acct-${_accounts.length + 1}',
      name: trimmedName,
      email: normalizedEmail,
      passwordHash: hashPasswordForDemo(password),
      role: role,
      linkedId: linkedId,
    );
    _accounts.add(account);
    currentAccount = account;
    notifyListeners();
    return AuthResult.success(account);
  }

  AuthResult signIn({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = hashPasswordForDemo(password);
    for (final account in _accounts) {
      if (account.email == normalizedEmail) {
        if (account.passwordHash != passwordHash) break;
        currentAccount = account;
        notifyListeners();
        return AuthResult.success(account);
      }
    }
    return const AuthResult.failure('Incorrect email or password.');
  }

  void signOut() {
    currentAccount = null;
    notifyListeners();
  }

  Customer customerById(String id) => customers.firstWhere((c) => c.id == id);

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
      customerId: currentCustomer.id,
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
    final order = orders.firstWhere((o) => o.id == orderId);
    _mutate(orderId, (o) {
      o.status = OrderStatus.accepted;
      o.logEvent('Partner accepted the order.');
    });
    notificationService.notify(order.customerId, 'Your order $orderId has been accepted.');
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
