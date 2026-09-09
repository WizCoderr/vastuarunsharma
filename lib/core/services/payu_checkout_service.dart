import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

import '../../data/models/response/order_response.dart';

typedef PayuHashGenerator = Future<String> Function({
  required String txnid,
  required String hashName,
  String? hashString,
  String? hashType,
  String? postSalt,
});

class PayuCheckoutResult {
  final String txnid;
  final String? mihpayid;
  final Map<String, dynamic>? raw;

  const PayuCheckoutResult({
    required this.txnid,
    this.mihpayid,
    this.raw,
  });
}

class PayuCheckoutCancelledException implements Exception {
  final String message;
  PayuCheckoutCancelledException([this.message = 'Payment cancelled']);
  @override
  String toString() => message;
}

class PayuCheckoutFailedException implements Exception {
  final String message;
  PayuCheckoutFailedException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around payu_checkoutpro_flutter for one-shot checkout.
class PayuCheckoutService implements PayUCheckoutProProtocol {
  PayuCheckoutService({required PayuHashGenerator generateHashFn})
      : _generateHashFn = generateHashFn;

  final PayuHashGenerator _generateHashFn;
  late final PayUCheckoutProFlutter _checkoutPro =
      PayUCheckoutProFlutter(this);

  Completer<PayuCheckoutResult>? _completer;
  String _txnid = '';

  Future<PayuCheckoutResult> open(PayuPaymentParams params) {
    if (params.key.trim().isEmpty || params.txnid.trim().isEmpty) {
      return Future.error(Exception('PayU key and txnid are required'));
    }

    _txnid = params.txnid;
    _completer = Completer<PayuCheckoutResult>();

    final payUPaymentParams = {
      PayUPaymentParamKey.key: params.key,
      PayUPaymentParamKey.transactionId: params.txnid,
      PayUPaymentParamKey.amount: params.amount,
      PayUPaymentParamKey.productInfo: params.productinfo,
      PayUPaymentParamKey.firstName: params.firstname,
      PayUPaymentParamKey.email: params.email,
      PayUPaymentParamKey.phone: params.phone,
      PayUPaymentParamKey.android_surl: params.surl,
      PayUPaymentParamKey.android_furl: params.furl,
      PayUPaymentParamKey.ios_surl: params.surl,
      PayUPaymentParamKey.ios_furl: params.furl,
      PayUPaymentParamKey.environment: params.environment,
      PayUPaymentParamKey.userCredential: '${params.key}:${params.email}',
      PayUPaymentParamKey.additionalParam: {
        PayUAdditionalParamKeys.udf1: params.udf1,
        PayUAdditionalParamKeys.udf2: params.udf2,
        PayUAdditionalParamKeys.udf3: params.udf3,
        PayUAdditionalParamKeys.udf4: params.udf4,
        PayUAdditionalParamKeys.udf5: params.udf5,
        'payment': params.hash,
      },
    };

    final payUConfigParams = {
      PayUCheckoutProConfigKeys.primaryColor: '#1B5E20',
      PayUCheckoutProConfigKeys.merchantName: 'Vastu Arun Sharma',
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: true,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: true,
    };

    _checkoutPro.openCheckoutScreen(
      payUPaymentParams: payUPaymentParams,
      payUCheckoutProConfig: payUConfigParams,
    );

    return _completer!.future;
  }

  void _completeOk(PayuCheckoutResult result) {
    final c = _completer;
    if (c == null || c.isCompleted) return;
    c.complete(result);
  }

  void _completeError(Object error) {
    final c = _completer;
    if (c == null || c.isCompleted) return;
    c.completeError(error);
  }

  @override
  generateHash(Map response) async {
    try {
      final hashName =
          response[PayUHashConstantsKeys.hashName]?.toString() ?? '';
      final hashString =
          response[PayUHashConstantsKeys.hashString]?.toString();
      final hashType = response[PayUHashConstantsKeys.hashType]?.toString();
      final postSalt = response[PayUHashConstantsKeys.postSalt]?.toString();

      final hash = await _generateHashFn(
        txnid: _txnid,
        hashName: hashName,
        hashString: hashString,
        hashType: hashType,
        postSalt: postSalt,
      );

      _checkoutPro.hashGenerated(hash: {hashName: hash});
    } catch (e) {
      debugPrint('PayU generateHash failed: $e');
      _checkoutPro.hashGenerated(hash: {});
      _completeError(PayuCheckoutFailedException('Hash generation failed: $e'));
    }
  }

  @override
  onPaymentSuccess(dynamic response) {
    final map = _asMap(response);
    final mihpayid = (map['mihpayid'] ?? map['id'] ?? '').toString();
    final txnid = (map['txnid'] ?? _txnid).toString();
    _completeOk(PayuCheckoutResult(
      txnid: txnid,
      mihpayid: mihpayid.isEmpty ? null : mihpayid,
      raw: map,
    ));
  }

  @override
  onPaymentFailure(dynamic response) {
    final map = _asMap(response);
    final message = (map['error_Message'] ??
            map['error'] ??
            map['message'] ??
            'Payment failed')
        .toString();
    _completeError(PayuCheckoutFailedException(message));
  }

  @override
  onPaymentCancel(Map? response) {
    _completeError(PayuCheckoutCancelledException());
  }

  @override
  onError(Map? response) {
    final message =
        (response?['error_message'] ?? response?['error'] ?? 'PayU error')
            .toString();
    _completeError(PayuCheckoutFailedException(message));
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) {
      return response.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }
}
