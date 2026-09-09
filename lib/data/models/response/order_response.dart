class PayuPaymentParams {
  final String key;
  final String txnid;
  final String amount;
  final String productinfo;
  final String firstname;
  final String email;
  final String phone;
  final String surl;
  final String furl;
  final String hash;
  final String paymentUrl;
  final String environment;
  final String udf1;
  final String udf2;
  final String udf3;
  final String udf4;
  final String udf5;
  final String? shopOrderId;
  final String? stageName;

  const PayuPaymentParams({
    required this.key,
    required this.txnid,
    required this.amount,
    required this.productinfo,
    required this.firstname,
    required this.email,
    required this.phone,
    required this.surl,
    required this.furl,
    required this.hash,
    required this.paymentUrl,
    required this.environment,
    this.udf1 = '',
    this.udf2 = '',
    this.udf3 = '',
    this.udf4 = '',
    this.udf5 = '',
    this.shopOrderId,
    this.stageName,
  });

  /// Convenience alias for txnid (used by some UI call sites).
  String get id => txnid;

  /// PayU requires amount as a string with exactly two decimal places.
  static String formatAmount(Object? raw) {
    final parsed = double.tryParse(raw?.toString() ?? '') ?? 0;
    return parsed.toStringAsFixed(2);
  }

  PayuPaymentParams withNormalizedAmount() {
    final normalized = formatAmount(amount);
    if (normalized == amount) return this;
    return PayuPaymentParams(
      key: key,
      txnid: txnid,
      amount: normalized,
      productinfo: productinfo,
      firstname: firstname,
      email: email,
      phone: phone,
      surl: surl,
      furl: furl,
      hash: hash,
      paymentUrl: paymentUrl,
      environment: environment,
      udf1: udf1,
      udf2: udf2,
      udf3: udf3,
      udf4: udf4,
      udf5: udf5,
      shopOrderId: shopOrderId,
      stageName: stageName,
    );
  }

  factory PayuPaymentParams.fromJson(Map<String, dynamic> json) {
    return PayuPaymentParams(
      key: (json['key'] ?? json['keyId'] ?? '').toString(),
      txnid: (json['txnid'] ?? json['id'] ?? json['orderId'] ?? '').toString(),
      amount: formatAmount(json['amount'] ?? '0.00'),
      productinfo: (json['productinfo'] ?? 'Payment').toString(),
      firstname: (json['firstname'] ?? 'Customer').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '9999999999').toString(),
      surl: (json['surl'] ?? json['android_surl'] ?? '').toString(),
      furl: (json['furl'] ?? json['android_furl'] ?? '').toString(),
      hash: (json['hash'] ?? '').toString(),
      paymentUrl: (json['paymentUrl'] ?? '').toString(),
      environment: (json['environment'] ?? '1').toString(),
      udf1: (json['udf1'] ?? '').toString(),
      udf2: (json['udf2'] ?? '').toString(),
      udf3: (json['udf3'] ?? '').toString(),
      udf4: (json['udf4'] ?? '').toString(),
      udf5: (json['udf5'] ?? '').toString(),
      shopOrderId: json['shopOrderId']?.toString(),
      stageName: json['stageName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'txnid': txnid,
        'amount': amount,
        'productinfo': productinfo,
        'firstname': firstname,
        'email': email,
        'phone': phone,
        'surl': surl,
        'furl': furl,
        'hash': hash,
        'paymentUrl': paymentUrl,
        'environment': environment,
        'udf1': udf1,
        'udf2': udf2,
        'udf3': udf3,
        'udf4': udf4,
        'udf5': udf5,
        if (shopOrderId != null) 'shopOrderId': shopOrderId,
        if (stageName != null) 'stageName': stageName,
      };
}

/// @deprecated Prefer [PayuPaymentParams]
typedef OrderResponse = PayuPaymentParams;

class PayuStatusResponse {
  final String txnid;
  final String status;
  final String amount;
  final String? mihpayid;
  final String? orderId;
  final String? courseId;
  final String type;

  const PayuStatusResponse({
    required this.txnid,
    required this.status,
    required this.amount,
    this.mihpayid,
    this.orderId,
    this.courseId,
    required this.type,
  });

  bool get isPaid =>
      status.toUpperCase() == 'PAID' ||
      status.toUpperCase() == 'COMPLETED' ||
      status.toLowerCase() == 'success';

  factory PayuStatusResponse.fromJson(Map<String, dynamic> json) {
    return PayuStatusResponse(
      txnid: (json['txnid'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      mihpayid: json['mihpayid']?.toString(),
      orderId: json['orderId']?.toString(),
      courseId: json['courseId']?.toString(),
      type: (json['type'] ?? 'PRODUCT').toString(),
    );
  }
}
