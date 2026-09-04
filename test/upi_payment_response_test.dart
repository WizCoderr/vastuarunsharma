import 'package:flutter_test/flutter_test.dart';
import 'package:vastuarunsharma/data/models/response/upi_payment_response.dart';

void main() {
  test('UpiPaymentResponse parses backend payload', () {
    final payment = UpiPaymentResponse.fromJson({
      'transactionId': 'TXN123',
      'upiUrl': 'upi://pay?pa=test',
      'qrCode': 'abc',
      'amount': 999,
      'deepLinks': {
        'google_pay': 'tez://upi/pay?pa=test',
      },
    });

    expect(payment.transactionId, 'TXN123');
    expect(payment.deepLinks?['google_pay'], contains('tez://'));
  });
}
