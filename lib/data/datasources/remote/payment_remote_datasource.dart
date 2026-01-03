import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/response/api_response.dart';
import '../../models/response/order_response.dart';
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

  Future<bool> verifyPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature,
    String courseId,
  ) async {
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
}
