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

  Future<OrderResponse> createOrder(String courseId) async {
    try {
      if (courseId.trim().isEmpty) {
        debugPrint('CreateOrder: empty courseId provided');
        throw Exception('courseId is required');
      }

      final payload = {'courseId': courseId};
      debugPrint('CreateOrder payload: $payload');

      final resp = await client.post(
        ApiEndpoints.courseOrder,
        data: payload,
      );

      debugPrint('CreateOrder response status: ${resp.statusCode}');
      debugPrint('CreateOrder raw body: ${resp.data}');

      final body = resp.data;
      return _parseOrderResponse(body, resp);
    } on DioException catch (e) {
      final uri = e.requestOptions.uri.toString();
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = 'CreateOrder failed: $uri -> $status ${body ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      debugPrint('CreateOrder unexpected error: $e');
      rethrow;
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

  Future<OrderResponse> createRemediesOrder(String orderId) async {
    try {
      if (orderId.trim().isEmpty) {
        debugPrint('createRemediesOrder: empty orderId provided');
        throw Exception('orderId is required');
      }

      final payload = {'orderId': orderId};
      debugPrint('createRemediesOrder payload: $payload');

      final resp = await client.post(
        ApiEndpoints.remediesOrder,
        data: payload,
      );

      debugPrint('createRemediesOrder response status: ${resp.statusCode}');
      debugPrint('createRemediesOrder raw body: ${resp.data}');

      final body = resp.data;
      return _parseOrderResponse(body, resp);
    } on DioException catch (e) {
      final uri = e.requestOptions.uri.toString();
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg =
          'createRemediesOrder failed: $uri -> $status ${body ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      debugPrint('createRemediesOrder unexpected error: $e');
      rethrow;
    }
  }

  OrderResponse _parseOrderResponse(dynamic body, Response resp) {
    Map<String, dynamic> orderJson;

    if (body is Map<String, dynamic>) {
      // Case 1: Standard wrapped response { success: true, data: { ... } }
      if (body.containsKey('success') &&
          body['data'] is Map<String, dynamic>) {
        orderJson = Map<String, dynamic>.from(
          body['data'] as Map<String, dynamic>,
        );
      }
      // Case 2: Some endpoints return { data: { ... } }
      else if (body.containsKey('data') &&
          body['data'] is Map<String, dynamic>) {
        orderJson = Map<String, dynamic>.from(
          body['data'] as Map<String, dynamic>,
        );
      }
      // Case 3: Raw order object like { orderId: '...', amount: 50000, keyId: '...' }
      else if (body.containsKey('orderId') || body.containsKey('id')) {
        orderJson = Map<String, dynamic>.from(body);
        if (orderJson.containsKey('orderId')) {
          orderJson['id'] = orderJson.remove('orderId');
        }
        if (orderJson.containsKey('keyId')) {
          orderJson['key'] = orderJson.remove('keyId');
        }
      } else {
        final errMsg = 'Unexpected createOrder response: ${resp.data}';
        debugPrint(errMsg);
        throw Exception(errMsg);
      }

      return OrderResponse.fromJson(orderJson);
    }

    final errMsg =
        'Unexpected createOrder response type: ${resp.data.runtimeType}';
    throw Exception(errMsg);
  }

  Future<List<StudentPaymentModel>> getStudentCoursePayments(
    String courseId,
  ) async {
    try {
      final resp = await client.get(ApiEndpoints.studentCoursePayments(courseId));
      final api = ApiResponse<List<dynamic>>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j as List<dynamic>,
      );

      if (api.success) {
        return api.data
                ?.map(
                  (e) => StudentPaymentModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [];
      }
      throw Exception(api.message ?? 'Failed to fetch student payments');
    } catch (e) {
      debugPrint('GetStudentCoursePayments error: $e');
      rethrow;
    }
  }

  Future<String?> verifyPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature, {
    required String courseId,
  }) async {
    try {
      // Validate exact required params
      if (razorpayOrderId.trim().isEmpty ||
          razorpayPaymentId.trim().isEmpty ||
          razorpaySignature.trim().isEmpty ||
          courseId.trim().isEmpty) {
        debugPrint(
          'VerifyPayment: missing required fields -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature course:$courseId',
        );
        throw Exception('Incomplete payment details');
      }

      final payload = {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'courseId': courseId,
      };

      debugPrint('VerifyPayment payload: $payload');

      final resp =
          await client.post(ApiEndpoints.courseVerify, data: payload);

      debugPrint('VerifyPayment response status: ${resp.statusCode}');
      debugPrint('VerifyPayment response body: ${resp.data}');

      final api = ApiResponse<dynamic>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j,
      );

      if (api.success) {
        // Response data might contain serialNumber directly or inside a map
        if (api.data is Map<String, dynamic>) {
          return api.data['serialNumber'] as String?;
        }
        return api.data?.toString();
      }

      final errMsg = api.message ?? 'Payment verification failed: ${resp.data}';
      throw Exception(errMsg);
    } on DioException catch (e) {
      final uri = e.requestOptions.uri.toString();
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = 'VerifyPayment failed: $uri -> $status ${body ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      debugPrint('VerifyPayment unexpected error: $e');
      rethrow;
    }
  }

  Future<bool> verifyRemediesPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature,
    String orderId,
  ) async {
    try {
      // Validate exact required params
      if (razorpayOrderId.trim().isEmpty ||
          razorpayPaymentId.trim().isEmpty ||
          razorpaySignature.trim().isEmpty ||
          orderId.trim().isEmpty) {
        debugPrint(
          'verifyRemediesPayment: missing required fields -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature orderId:$orderId',
        );
        throw Exception('Incomplete payment details');
      }

      final payload = {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'orderId': orderId,
      };

      debugPrint('verifyRemediesPayment payload: $payload');

      final resp =
          await client.post(ApiEndpoints.remediesVerify, data: payload);

      debugPrint(
          'verifyRemediesPayment response status: ${resp.statusCode}');
      debugPrint('verifyRemediesPayment response body: ${resp.data}');

      final api = ApiResponse<dynamic>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j,
      );

      if (api.success) {
        return true;
      }

      final errMsg =
          api.message ?? 'Payment verification failed: ${resp.data}';
      throw Exception(errMsg);
    } on DioException catch (e) {
      final uri = e.requestOptions.uri.toString();
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg =
          'verifyRemediesPayment failed: $uri -> $status ${body ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      debugPrint('verifyRemediesPayment unexpected error: $e');
      rethrow;
    }
  }

  Future<bool> freeEnroll(String courseId) async {
    try {
      if (courseId.trim().isEmpty) {
        throw Exception('courseId is required');
      }

      final payload = {'courseId': courseId};
      debugPrint('FreeEnroll payload: $payload');

      final resp = await client.post(ApiEndpoints.freeEnroll, data: payload);

      debugPrint('FreeEnroll response status: ${resp.statusCode}');
      debugPrint('FreeEnroll response body: ${resp.data}');

      // Handle null or empty response
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

      final errMsg = api.message ?? 'Free enrollment failed: ${resp.data}';
      throw Exception(errMsg);
    } on DioException catch (e) {
      final uri = e.requestOptions.uri.toString();
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = 'FreeEnroll failed: $uri -> $status ${body ?? e.message}';
      debugPrint(msg);
      throw Exception(msg);
    } catch (e) {
      debugPrint('FreeEnroll unexpected error: $e');
      rethrow;
    }
  }
}
