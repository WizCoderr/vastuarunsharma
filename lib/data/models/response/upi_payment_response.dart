class UpiPaymentResponse {
  final String transactionId;
  final String upiUrl;
  final String qrCode;
  final String? orderId;
  final double? amount;
  final Map<String, String>? deepLinks;

  UpiPaymentResponse({
    required this.transactionId,
    required this.upiUrl,
    required this.qrCode,
    this.orderId,
    this.amount,
    this.deepLinks,
  });

  factory UpiPaymentResponse.fromJson(Map<String, dynamic> json) {
    final deepLinksRaw = json['deepLinks'];
    Map<String, String>? deepLinks;
    if (deepLinksRaw is Map) {
      deepLinks = deepLinksRaw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return UpiPaymentResponse(
      transactionId: json['transactionId'] as String? ?? json['id'] as String? ?? '',
      upiUrl: json['upiUrl'] as String? ?? '',
      qrCode: json['qrCode'] as String? ?? '',
      orderId: json['orderId'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      deepLinks: deepLinks,
    );
  }
}

class PaymentStatusResponse {
  final String transactionId;
  final String status;
  final double amount;
  final String? utr;
  final String? invoiceUrl;

  PaymentStatusResponse({
    required this.transactionId,
    required this.status,
    required this.amount,
    this.utr,
    this.invoiceUrl,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      transactionId: json['transactionId'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      utr: json['utr'] as String?,
      invoiceUrl: json['invoiceUrl'] as String?,
    );
  }

  bool get isTerminal =>
      status == 'COMPLETED' || status == 'PAID' || status == 'FAILED';
}
