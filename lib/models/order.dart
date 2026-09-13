import '../utils/formatters.dart';
import 'address.dart';
import 'enums.dart';

class OrderItem {
  const OrderItem({
    required this.catalogItemId,
    required this.name,
    required this.serviceType,
    required this.quantity,
    required this.unitPrice,
  });

  final String catalogItemId;
  final String name;
  final ServiceType serviceType;
  final int quantity;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;
}

class TimeSlot {
  const TimeSlot(this.start, this.end);

  final DateTime start;
  final DateTime end;

  String get label {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
  }
}

/// A single laundry order moving through the pickup → wash/iron → delivery
/// pipeline. Carries its own commission math so every screen (partner,
/// admin) reads the same numbers instead of recomputing them.
class LaundryOrder {
  LaundryOrder({
    required this.id,
    required this.customerId,
    required this.partnerId,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupSlot,
    this.deliverySlot,
    this.status = OrderStatus.pending,
    this.pickupDriverId,
    this.deliveryDriverId,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    required this.commissionRate,
    this.deliveryFee = kDeliveryFee,
    DateTime? createdAt,
    List<String>? activityLog,
  })  : createdAt = createdAt ?? DateTime.now(),
        activityLog = activityLog ?? [];

  final String id;
  final String customerId;
  final String partnerId;
  final List<OrderItem> items;
  final Address pickupAddress;
  final Address deliveryAddress;
  final TimeSlot pickupSlot;
  final TimeSlot? deliverySlot;
  OrderStatus status;
  String? pickupDriverId;
  String? deliveryDriverId;
  final PaymentMethod paymentMethod;
  PaymentStatus paymentStatus;

  /// Snapshot of the partner's commission rate at order time, so a later
  /// rate change never rewrites the economics of a past order.
  final double commissionRate;
  final double deliveryFee;
  final DateTime createdAt;
  final List<String> activityLog;

  /// Value of the laundry service itself (what the commission is taken on).
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  double get commissionAmount => subtotal * commissionRate;

  /// What the laundry partner is paid out for this order.
  double get partnerPayout => subtotal - commissionAmount;

  /// What the customer is charged: service items + the flat delivery fee.
  double get total => subtotal + deliveryFee;

  void logEvent(String message) {
    activityLog.add('${DateTime.now().toIso8601String()}: $message');
  }
}
