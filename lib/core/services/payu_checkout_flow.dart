import '../../data/models/response/order_response.dart';
import 'payu_checkout_service.dart';

enum PayuCheckoutPhase {
  /// CheckoutPro UI is open / awaiting user payment.
  waitingForPayu,

  /// SDK reported success; polling backend for fulfillment.
  confirming,
}

/// Shared create-params → CheckoutPro → status-poll runner used by
/// remidies, course, and installment payment screens.
class PayuCheckoutFlow {
  PayuCheckoutFlow._();

  static void validateParams(PayuPaymentParams params) {
    if (params.key.trim().isEmpty || params.txnid.trim().isEmpty) {
      throw Exception('Payment gateway is not configured');
    }
    if (params.hash.trim().isEmpty) {
      throw Exception('Incomplete PayU payment parameters (missing hash)');
    }
    if (params.surl.trim().isEmpty || params.furl.trim().isEmpty) {
      throw Exception('Incomplete PayU payment parameters (missing surl/furl)');
    }
    if (params.environment.trim().isEmpty) {
      throw Exception('Incomplete PayU payment parameters (missing environment)');
    }
  }

  /// Opens CheckoutPro then polls until the backend marks the txn paid/failed.
  ///
  /// Rethrows [PayuCheckoutCancelledException] / [PayuCheckoutFailedException]
  /// unchanged so callers can branch on cancel vs failure.
  static Future<PayuStatusResponse> run({
    required PayuPaymentParams params,
    required PayuHashGenerator generateHashFn,
    required Future<PayuStatusResponse> Function(String txnid) waitForFulfillment,
    void Function(PayuCheckoutPhase phase)? onPhase,
  }) async {
    final normalized = params.withNormalizedAmount();
    validateParams(normalized);

    onPhase?.call(PayuCheckoutPhase.waitingForPayu);

    final checkout = PayuCheckoutService(generateHashFn: generateHashFn);
    final result = await checkout.open(normalized);

    onPhase?.call(PayuCheckoutPhase.confirming);

    final status = await waitForFulfillment(result.txnid);
    if (!status.isPaid) {
      throw Exception('Payment not confirmed (${status.status})');
    }
    return status;
  }
}
