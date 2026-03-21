import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/response/api_response.dart';
import '../../models/response/order_response.dart';
import '../../models/course_model.dart';
import '../../models/response/student_payment_model.dart';
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
        ApiEndpoints.createrazorpayorder,
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

  Future<List<PaymentPlanModel>> getPaymentPlan(String courseId) async {
    try {
      final resp = await client.get(ApiEndpoints.coursePaymentPlan(courseId));
      final api = ApiResponse<List<dynamic>>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j as List<dynamic>,
      );

      if (api.success) {
        return api.data
                ?.map((e) => PaymentPlanModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      }
      throw Exception(api.message ?? 'Failed to fetch payment plan');
    } catch (e) {
      debugPrint('GetPaymentPlan error: $e');
      rethrow;
    }
  }

  Future<OrderResponse> enrollInCourse(String courseId) async {
    try {
      final resp = await client.post(ApiEndpoints.enrollInCourse(courseId));
      return _parseOrderResponse(resp.data, resp);
    } catch (e) {
      debugPrint('EnrollInCourse error: $e');
      rethrow;
    }
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

  Future<OrderResponse> payInstallment(String paymentId) async {
    try {
      final resp = await client.post(ApiEndpoints.payInstallment(paymentId));
      return _parseOrderResponse(resp.data, resp);
    } catch (e) {
      debugPrint('PayInstallment error: $e');
      rethrow;
    }
  }

  Future<bool> verifyPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature,
    String courseId, {
    String? paymentId,
  }) async {
    try {
      // Validate exact required params
      if (razorpayOrderId.trim().isEmpty ||
          razorpayPaymentId.trim().isEmpty ||
          razorpaySignature.trim().isEmpty ||
          (courseId.trim().isEmpty && paymentId == null)) {
        debugPrint(
          'VerifyPayment: missing required fields -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature course:$courseId paymentId:$paymentId',
        );
        throw Exception('Incomplete payment details');
      }

      final payload = {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        if (courseId.isNotEmpty) 'courseId': courseId,
        'paymentId': paymentId,
      };

      debugPrint('VerifyPayment payload: $payload');

      final resp = await client.post(ApiEndpoints.verifyPayment, data: payload);

      debugPrint('VerifyPayment response status: ${resp.statusCode}');
      debugPrint('VerifyPayment response body: ${resp.data}');

      final api = ApiResponse<dynamic>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j,
      );

      if (api.success) {
        return true;
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
