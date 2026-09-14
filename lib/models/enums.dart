/// The five sides of the marketplace. `staff` is the laundry hub's own
/// operations team (inspection/processing/QC) — see `UserRole.staff`'s doc
/// for how that differs from `partner`.
enum UserRole { customer, partner, driver, admin, staff }

/// The three service families every partner prices per item.
enum ServiceType { washFold, dryClean, ironing }

/// Lifecycle of an order — Order+Bag+Item+Process-centric, not just
/// order-centric, per the laundry-specific pipeline (pickup → hub →
/// inspect → process → QC → delivery) rather than a restaurant's pickup →
/// immediate delivery. Each stage names who normally drives it:
///
///   pending              customer places the order
///   accepted             partner accepts it
///   pickupAssigned       partner assigns a pickup driver
///   pickedUp             driver collects it from the customer
///   atHub                driver drops it at the hub (a `LaundryOrder` gets
///                        its `bagId` here)
///   inspecting           staff verify/adjust item counts, note any
///                        pre-existing damage
///   processing           staff work it through `ProcessingStage`
///                        (received → sorting → washing → ... → packing)
///   qualityCheck         staff complete the QC checklist
///   readyForDelivery     QC passed
///   deliveryAssigned     partner assigns a delivery driver
///   outForDelivery       driver is en route (an OTP is generated here)
///   delivered            driver confirms with the OTP the customer gives
///                        them
///   cancelled            terminal, from anywhere
enum OrderStatus {
  pending,
  accepted,
  pickupAssigned,
  pickedUp,
  atHub,
  inspecting,
  processing,
  qualityCheck,
  readyForDelivery,
  deliveryAssigned,
  outForDelivery,
  delivered,
  cancelled,
}

/// The internal wash/dry/iron pipeline an order works through while its
/// `OrderStatus` is `processing`. Tracked separately from `OrderStatus` so
/// the customer-facing stepper doesn't need to know about every internal
/// hub step; staff advance it one stage at a time.
enum ProcessingStage { received, sorting, washing, drying, ironing, folding, packing }

enum PaymentMethod { card, wallet, cashOnDelivery }

enum PaymentStatus { pending, paid, failed, refunded }

enum DisputeStatus { open, resolved }

/// KYC/onboarding document review status for Partner and Driver accounts —
/// set to `pending` the moment they sign up and submit documents. Nothing
/// in this demo currently flips it to `verified`/`rejected`; a real backend
/// would do that once a human (or an ID-verification vendor) reviews the
/// uploaded documents.
enum VerificationStatus { pending, verified, rejected }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending confirmation';
      case OrderStatus.accepted:
        return 'Accepted by laundry';
      case OrderStatus.pickupAssigned:
        return 'Driver assigned (pickup)';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.atHub:
        return 'At the laundry hub';
      case OrderStatus.inspecting:
        return 'Being inspected';
      case OrderStatus.processing:
        return 'Being processed';
      case OrderStatus.qualityCheck:
        return 'Quality check';
      case OrderStatus.readyForDelivery:
        return 'Ready for delivery';
      case OrderStatus.deliveryAssigned:
        return 'Driver assigned (delivery)';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// True while the order still needs someone's attention; false once it has
  /// reached a terminal state.
  bool get isActive => this != OrderStatus.delivered && this != OrderStatus.cancelled;
}

extension ProcessingStageX on ProcessingStage {
  String get label {
    switch (this) {
      case ProcessingStage.received:
        return 'Received';
      case ProcessingStage.sorting:
        return 'Sorting';
      case ProcessingStage.washing:
        return 'Washing';
      case ProcessingStage.drying:
        return 'Drying';
      case ProcessingStage.ironing:
        return 'Ironing';
      case ProcessingStage.folding:
        return 'Folding';
      case ProcessingStage.packing:
        return 'Packing';
    }
  }

  /// The next stage after this one, or null once at the last (`packing`) —
  /// null means "processing is done; complete it to move to QC".
  ProcessingStage? get next {
    const stages = ProcessingStage.values;
    final i = stages.indexOf(this);
    return i + 1 < stages.length ? stages[i + 1] : null;
  }
}

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.washFold:
        return 'Wash & Fold';
      case ServiceType.dryClean:
        return 'Dry Cleaning';
      case ServiceType.ironing:
        return 'Ironing';
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit / Debit Card';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }
}

extension VerificationStatusX on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}
