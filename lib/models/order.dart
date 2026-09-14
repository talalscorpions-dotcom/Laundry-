import '../utils/formatters.dart';
import 'address.dart';
import 'enums.dart';

class OrderItem {
  OrderItem({
    required this.catalogItemId,
    required this.name,
    required this.serviceType,
    required this.quantity,
    required this.unitPrice,
    int? actualQuantity,
  }) : actualQuantity = actualQuantity ?? quantity;

  final String catalogItemId;
  final String name;
  final ServiceType serviceType;

  /// What the customer estimated when placing the order.
  final int quantity;
  final double unitPrice;

  /// What staff actually counted during inspection (`AppState.recordInspection`).
  /// Defaults to [quantity] until inspection overwrites it — billing always
  /// follows this field, not the customer's estimate, so a recount changes
  /// [lineTotal] (and the customer sees why, via [LaundryOrder.inspectionNotes]).
  int actualQuantity;

  bool get quantityAdjustedByStaff => actualQuantity != quantity;

  double get lineTotal => unitPrice * actualQuantity;
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
    this.bagId,
    this.processingStage,
    List<String>? inspectionNotes,
    List<String>? inspectionPhotoNames,
    this.deliveryOtp,
  })  : createdAt = createdAt ?? DateTime.now(),
        activityLog = activityLog ?? [],
        inspectionNotes = inspectionNotes ?? [],
        inspectionPhotoNames = inspectionPhotoNames ?? [];

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

  /// Set once a driver drops the order at the hub (`AppState.markDroppedOffAtHub`)
  /// — stands in for a real printed/scanned QR or barcode tag on the bag.
  String? bagId;

  /// Only meaningful while [status] is [OrderStatus.processing]; null before
  /// and after (QC/ready/etc. don't track a wash-pipeline sub-stage).
  ProcessingStage? processingStage;

  /// Free-text notes staff add during inspection (e.g. "1 shirt missing a
  /// button", "coffee stain, pre-treated") — shown to the customer alongside
  /// any [quantity]/[actualQuantity] mismatch.
  final List<String> inspectionNotes;

  /// File names of photos staff attach during inspection to document
  /// pre-existing damage. Demo-only: just remembers a name (see
  /// `DocumentPickerField`'s caveat) — a real pipeline uploads to cloud
  /// storage and stores URLs here instead.
  final List<String> inspectionPhotoNames;

  /// A short code generated when the order goes [OrderStatus.outForDelivery]
  /// (`AppState.markOutForDelivery`) and given to the customer; the driver
  /// must collect it back from them to confirm delivery
  /// (`AppState.confirmDelivery`) instead of just tapping "delivered".
  String? deliveryOtp;

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
