import '../models/enums.dart';

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.transactionId,
    this.failureReason,
  });

  final bool success;
  final String transactionId;
  final String? failureReason;
}

/// Abstraction over a payment gateway so a real provider (Stripe, PayTabs,
/// Apple/Google Pay, a local bank gateway, a wallet aggregator...) can be
/// dropped in without touching ordering logic or UI. Swap the instance
/// handed to `AppState` in `main.dart`.
abstract class PaymentGateway {
  Future<PaymentResult> charge({
    required String orderId,
    required double amount,
    required PaymentMethod method,
  });
}

/// Simulated gateway used by this MVP. Cards/wallets are "charged"
/// immediately; cash on delivery is collected later by the driver, so it is
/// not charged up front.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge({
    required String orderId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (method == PaymentMethod.cashOnDelivery) {
      return PaymentResult(success: true, transactionId: 'COD-$orderId');
    }
    return PaymentResult(
      success: true,
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
