import 'enums.dart';

/// A complaint raised against an order (missing item, damaged garment, late
/// pickup...) that the admin panel tracks through to resolution.
class Dispute {
  Dispute({
    required this.id,
    required this.orderId,
    required this.raisedByRole,
    required this.reason,
    this.status = DisputeStatus.open,
    this.resolutionNotes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String orderId;
  final String raisedByRole; // 'customer' | 'partner' | 'driver'
  final String reason;
  DisputeStatus status;
  String? resolutionNotes;
  final DateTime createdAt;
}
