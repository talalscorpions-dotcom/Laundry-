/// The four sides of the marketplace.
enum UserRole { customer, partner, driver, admin }

/// The three service families every partner prices per item.
enum ServiceType { washFold, dryClean, ironing }

/// Lifecycle of an order, in the order a "happy path" order moves through.
/// `pickupAssigned`/`deliveryAssigned` are transient sub-states of
/// accepted/readyForDelivery that exist so a driver can be tracked live.
enum OrderStatus {
  pending,
  accepted,
  pickupAssigned,
  pickedUp,
  washing,
  ironing,
  readyForDelivery,
  deliveryAssigned,
  outForDelivery,
  delivered,
  cancelled,
}

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
      case OrderStatus.washing:
        return 'Washing';
      case OrderStatus.ironing:
        return 'Ironing';
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
