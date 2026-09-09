import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/response/api_response.dart';
import '../../models/response/order_response.dart';
import '../../models/response/student_payment_model.dart';
import '../../models/response/upi_payment_response.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_endpoints.dart';

class PaymentRemoteDataSource {
  final DioClient client;
  PaymentRemoteDataSource(this.client);

  Future<PayuPaymentParams> createOrder(String courseId) async {
    try {
      if (courseId.trim().isEmpty) {
        throw Exception('courseId is required');
      }

      final payload = {'courseId': courseId, 'channel': 'app'};
      final resp = await client.post(ApiEndpoints.courseOrder, data: payload);
      return _parsePayuParams(resp.data, resp);
    } on DioException catch (e) {
      final msg =
          'CreateOrder failed: ${e.requestOptions.uri} -> ${e.response?.statusCode} ${e.response?.data ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<UpiPaymentResponse> createRemediesUpiPayment(String orderId) async {
    final resp = await client.post(
      ApiEndpoints.remediesOrder,
      data: {'orderId': orderId},
    );
    return _parseUpiResponse(resp.data);
  }

  Future<UpiPaymentResponse> createCourseUpiPayment(String courseId) async {
    final resp = await client.post(
      ApiEndpoints.courseOrder,
      data: {'courseId': courseId},
    );
    return _parseUpiResponse(resp.data);
  }

  Future<PaymentStatusResponse> getPaymentStatus(String transactionId) async {
    final resp = await client.get(ApiEndpoints.paymentStatus(transactionId));
    return _parseStatusResponse(resp.data);
  }

  Future<void> verifyUpiPayment(String transactionId) async {
    await client.post(
      ApiEndpoints.verifyPayment,
      data: {'transactionId': transactionId},
    );
  }

  UpiPaymentResponse _parseUpiResponse(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
        return UpiPaymentResponse.fromJson(body['data'] as Map<String, dynamic>);
      }
      return UpiPaymentResponse.fromJson(body);
    }
    throw Exception('Invalid UPI payment response');
  }

  PaymentStatusResponse _parseStatusResponse(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
        return PaymentStatusResponse.fromJson(body['data'] as Map<String, dynamic>);
      }
      return PaymentStatusResponse.fromJson(body);
    }
    throw Exception('Invalid payment status response');
  }

  Future<PayuPaymentParams> createRemediesOrder(String orderId) async {
    try {
      if (orderId.trim().isEmpty) {
        throw Exception('orderId is required');
      }

      final payload = {'orderId': orderId, 'channel': 'app'};
      final resp = await client.post(ApiEndpoints.remediesOrder, data: payload);
      return _parsePayuParams(resp.data, resp);
    } on DioException catch (e) {
      final msg =
          'createRemediesOrder failed: ${e.requestOptions.uri} -> ${e.response?.statusCode} ${e.response?.data ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  PayuPaymentParams _parsePayuParams(dynamic body, Response resp) {
    Map<String, dynamic> orderJson;

    if (body is Map<String, dynamic>) {
      if (body.containsKey('success') && body['data'] is Map<String, dynamic>) {
        orderJson = Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
      } else if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
        orderJson = Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
      } else if (body.containsKey('txnid') ||
          body.containsKey('orderId') ||
          body.containsKey('id') ||
          body.containsKey('hash')) {
        orderJson = Map<String, dynamic>.from(body);
      } else {
        throw Exception('Unexpected createOrder response: ${resp.data}');
      }

      return PayuPaymentParams.fromJson(orderJson);
    }

    throw Exception(
      'Unexpected createOrder response type: ${resp.data.runtimeType}',
    );
  }

  Future<PayuPaymentParams> createInstallmentOrder(String paymentId) async {
    final resp = await client.post(
      ApiEndpoints.installmentOrder,
      data: {'paymentId': paymentId, 'channel': 'app'},
    );
    return _parsePayuParams(resp.data, resp);
  }

  Future<List<StudentPaymentModel>> getStudentCoursePayments(
    String courseId,
  ) async {
    try {
      final resp = await client.get(ApiEndpoints.studentCoursePayments(courseId));
      final body = resp.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid student payments response');
      }

      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      final listRaw = data['payments'];
      if (listRaw is! List) {
        if (body['data'] is List) {
          return (body['data'] as List)
              .map((e) => StudentPaymentModel.fromJson({
                    ...(e as Map<String, dynamic>),
                    'courseId': courseId,
                    'title': (e as Map)['title'] ?? e['stage'] ?? e['stageName'],
                  }))
              .toList();
        }
        throw Exception('Student payments list missing');
      }

      return listRaw.map((e) {
        final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
        map['courseId'] = map['courseId'] ?? courseId;
        map['title'] =
            map['title'] ?? map['stage'] ?? map['stageName'] ?? 'Installment';
        return StudentPaymentModel.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('GetStudentCoursePayments error: $e');
      rethrow;
    }
  }

  Future<String> generatePayuHash({
    required String txnid,
    required String hashName,
    String? hashString,
    String? hashType,
    String? postSalt,
  }) async {
    final resp = await client.post(
      ApiEndpoints.payuHash,
      data: {
        'txnid': txnid,
        'hashName': hashName,
        'hashString': ?hashString,
        'hashType': ?hashType,
        'postSalt': ?postSalt,
      },
    );

    final body = resp.data;
    Map<String, dynamic> data;
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(body['data'] as Map);
      } else {
        data = body;
      }
    } else {
      throw Exception('Invalid hash response');
    }

    final hash = data['hash']?.toString();
    if (hash == null || hash.isEmpty) {
      throw Exception('Hash missing from server response');
    }
    return hash;
  }

  Future<PayuStatusResponse> getPayuStatus(String txnid) async {
    final resp = await client.get(ApiEndpoints.payuStatus(txnid));
    final body = resp.data;
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return PayuStatusResponse.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      return PayuStatusResponse.fromJson(body);
    }
    throw Exception('Invalid PayU status response');
  }

  /// Polls backend until payment is fulfilled (or failed).
  /// Defaults ~60s so S2S verify can catch up when PayU cannot hit localhost callback.
  Future<PayuStatusResponse> waitForPayuFulfillment(
    String txnid, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    PayuStatusResponse? last;
    for (var i = 0; i < maxAttempts; i++) {
      last = await getPayuStatus(txnid);
      final s = last.status.toUpperCase();
      if (s == 'PAID' || s == 'COMPLETED' || s == 'FAILED' || s == 'REFUNDED') {
        return last;
      }
      await Future<void>.delayed(interval);
    }
    return last ??
        PayuStatusResponse(
          txnid: txnid,
          status: 'PENDING',
          amount: '',
          type: 'PRODUCT',
        );
  }

  Future<bool> freeEnroll(String courseId) async {
    try {
      if (courseId.trim().isEmpty) {
        throw Exception('courseId is required');
      }

      final resp = await client.post(
        ApiEndpoints.freeEnroll,
        data: {'courseId': courseId},
      );

      if (resp.data == null) {
        throw Exception('Empty response from server');
      }

      if (resp.data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response format: expected JSON object, got ${resp.data.runtimeType}',
        );
      }

      final api = ApiResponse<dynamic>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j,
      );

      if (api.success) {
        return true;
      }

      throw Exception(api.message ?? 'Free enrollment failed: ${resp.data}');
    } on DioException catch (e) {
      final msg =
          'FreeEnroll failed: ${e.requestOptions.uri} -> ${e.response?.statusCode} ${e.response?.data ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    }
  }
}
