import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/address.dart';
import '../models/dispute.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/user_models.dart';
import '../services/device_location_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../utils/password_hash.dart';
import '../utils/scheduling.dart';
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
    DeviceLocationService? deviceLocationService,
  })  : paymentGateway = paymentGateway ?? MockPaymentGateway(),
        locationTracker = locationTracker ?? SimulatedLocationTracker(),
        notificationService = notificationService ?? InMemoryNotificationService(),
        deviceLocationService = deviceLocationService ?? GeolocatorDeviceLocationService();

  final PaymentGateway paymentGateway;
  final LocationTracker locationTracker;
  final NotificationService notificationService;
  final DeviceLocationService deviceLocationService;

  // LaundryPartner, Driver, and Customer are all mutated in place at
  // runtime (see their copyForNewSession() doc comments), so each AppState
  // gets its own independent copies rather than sharing MockData's.
  final List<Customer> customers = MockData.customers.map((c) => c.copyForNewSession()).toList();
  final List<LaundryPartner> partners = MockData.partners.map((p) => p.copyForNewSession()).toList();
  final List<Driver> drivers = MockData.drivers.map((d) => d.copyForNewSession()).toList();
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
    required String phone,
    String? area,
    String? vehicle,
    String? addressLine,
    String? city,
    // Required for partner sign-up (an "ID" + a Commercial Registration)
    // and driver sign-up (a Residential ID + a Driver's Licence). These are
    // just the *file names* the user picked — see the caveat on
    // DocumentPickerField about what this demo does (and doesn't do) with
    // them.
    String? idDocumentName,
    String? commercialRegistrationDocumentName,
    String? residentialIdDocumentName,
    String? driverLicenseDocumentName,
  }) {
    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPhone = phone.trim();

    if (role == UserRole.admin) {
      return const AuthResult.failure('Admin accounts cannot self-register — contact an existing admin.');
    }
    if (trimmedName.isEmpty) {
      return const AuthResult.failure('Enter your name.');
    }
    if (!normalizedEmail.contains('@')) {
      return const AuthResult.failure('Enter a valid email address.');
    }
    if (trimmedPhone.isEmpty) {
      return const AuthResult.failure('Enter your phone number.');
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
          phone: trimmedPhone,
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
        if ((idDocumentName ?? '').trim().isEmpty) {
          return const AuthResult.failure('Upload an ID document.');
        }
        if ((commercialRegistrationDocumentName ?? '').trim().isEmpty) {
          return const AuthResult.failure('Upload your Commercial Registration.');
        }
        linkedId = 'partner-${_partnerSeq++}-${DateTime.now().millisecondsSinceEpoch}';
        partners.add(LaundryPartner(
          id: linkedId,
          name: trimmedName,
          phone: trimmedPhone,
          area: area!.trim(),
          // Placeholder — a real onboarding flow would collect a pinned
          // shop location.
          location: const GeoPoint(23.588, 58.407),
          rating: 5.0,
          isOpen: true,
          commissionRate: 0.20,
          catalog: const [],
          idDocumentName: idDocumentName!.trim(),
          commercialRegistrationDocumentName: commercialRegistrationDocumentName!.trim(),
        ));
        break;
      case UserRole.driver:
        if ((vehicle ?? '').trim().isEmpty) {
          return const AuthResult.failure('Enter your vehicle details.');
        }
        if ((residentialIdDocumentName ?? '').trim().isEmpty) {
          return const AuthResult.failure('Upload your Residential ID.');
        }
        if ((driverLicenseDocumentName ?? '').trim().isEmpty) {
          return const AuthResult.failure('Upload your Driver\'s Licence.');
        }
        linkedId = 'driver-${_driverSeq++}-${DateTime.now().millisecondsSinceEpoch}';
        drivers.add(Driver(
          id: linkedId,
          name: trimmedName,
          phone: trimmedPhone,
          vehicle: vehicle!.trim(),
          rating: 5.0,
          isAvailable: true,
          location: const GeoPoint(23.590, 58.410),
          residentialIdDocumentName: residentialIdDocumentName!.trim(),
          driverLicenseDocumentName: driverLicenseDocumentName!.trim(),
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

  /// Whether an account exists for [email] — used by the forgot-password
  /// flow to check before offering to reset a password.
  bool accountExistsForEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _accounts.any((a) => a.email == normalizedEmail);
  }

  /// Sets a new password for the account with [email].
  ///
  /// A real "forgot password" flow verifies ownership of the email first —
  /// a reset link (with a short-lived, single-use token) sent to that
  /// address, or a code — before ever accepting a new password. This demo
  /// has no email service to send that link through, so it skips straight
  /// to setting the new password once the email is known to exist. Do not
  /// ship that shortcut: it lets anyone who knows an email address reset
  /// that account's password.
  AuthResult resetPassword({required String email, required String newPassword}) {
    final normalizedEmail = email.trim().toLowerCase();
    final index = _accounts.indexWhere((a) => a.email == normalizedEmail);
    if (index == -1) {
      return const AuthResult.failure('No account found for that email.');
    }
    if (newPassword.length < 6) {
      return const AuthResult.failure('Password must be at least 6 characters.');
    }
    final existing = _accounts[index];
    final updated = Account(
      id: existing.id,
      name: existing.name,
      email: existing.email,
      passwordHash: hashPasswordForDemo(newPassword),
      role: existing.role,
      linkedId: existing.linkedId,
    );
    _accounts[index] = updated;
    notifyListeners();
    return AuthResult.success(updated);
  }

  Customer customerById(String id) => customers.firstWhere((c) => c.id == id);

  /// Saves a new address to [customerId]'s address book — the "Add a new
  /// address" step in the pickup/delivery address picker.
  void addCustomerAddress(String customerId, Address address) {
    customerById(customerId).addresses.add(address);
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

  /// Sets whether [driverId] is rostered for [slotIndex] (an index into
  /// `kSlotWindows`) on [weekday] (`DateTime.monday`..`DateTime.sunday`),
  /// every week. Called from the driver's "My schedule" screen.
  void setDriverSlotAvailability({
    required String driverId,
    required int weekday,
    required int slotIndex,
    required bool available,
  }) {
    final driver = driverById(driverId);
    if (driver == null) return;
    final daySlots = driver.weeklyAvailability.putIfAbsent(weekday, () => {});
    if (available) {
      daySlots.add(slotIndex);
    } else {
      daySlots.remove(slotIndex);
    }
    notifyListeners();
  }

  /// Replaces [driverId]'s entire weekly schedule at once with [availability]
  /// (weekday -> the set of slot indices rostered that day). Called once,
  /// from the "Confirm schedule" button, after the driver has finished
  /// editing a local draft — see [setDriverSlotAvailability] for the
  /// single-slot version other callers (and tests) use.
  void setDriverWeeklyAvailability(String driverId, Map<int, Set<int>> availability) {
    final driver = driverById(driverId);
    if (driver == null) return;
    driver.weeklyAvailability
      ..clear()
      ..addAll({for (final entry in availability.entries) entry.key: Set.of(entry.value)});
    notifyListeners();
  }

  /// How many drivers are, per their weekly schedule, rostered for the
  /// window [slot] falls in (matched by weekday + start hour) — regardless
  /// of whether they're already covering an order in it.
  int _rosteredDriverCountFor(TimeSlot slot) {
    final index = slotIndexForHour(slot.start.hour);
    if (index == null) return 0;
    return drivers.where((d) => d.isAvailableAt(slot.start.weekday, index)).length;
  }

  /// How many active orders already occupy this exact pickup window.
  int _bookedCountFor(TimeSlot slot) {
    return orders.where((o) => o.status.isActive && o.pickupSlot.start.isAtSameMomentAs(slot.start)).length;
  }

  /// Whether a customer can still book [slot] for pickup. False once every
  /// driver rostered for that weekday/window already has an order booked
  /// into it — shown to the customer as "Fully booked" on the schedule
  /// screen instead of a pickable time.
  bool isSlotFullyBooked(TimeSlot slot) {
    final rostered = _rosteredDriverCountFor(slot);
    if (rostered == 0) return true;
    return _bookedCountFor(slot) >= rostered;
  }

  /// Drivers rostered for [slot]'s weekday/window who aren't already
  /// covering another active pickup in that same window and haven't gone
  /// off-shift (`isAvailable`) — what a partner should be offered when
  /// assigning a pickup driver. Empty means the slot is fully booked.
  List<Driver> driversAvailableForSlot(TimeSlot slot) {
    final index = slotIndexForHour(slot.start.hour);
    if (index == null) return [];
    final busyDriverIds = orders
        .where((o) => o.status.isActive && o.pickupSlot.start.isAtSameMomentAs(slot.start))
        .map((o) => o.pickupDriverId)
        .whereType<String>()
        .toSet();
    return drivers
        .where((d) => d.isAvailable && d.isAvailableAt(slot.start.weekday, index) && !busyDriverIds.contains(d.id))
        .toList();
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
