import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_endpoints.dart';
import '../models/request/forgot_password_request.dart';
import '../models/request/reset_password_request.dart';
import '../models/response/auth_action_response.dart';

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (message) => debugPrint(message.toString()),
        ),
      );
    }

    return dio;
  }

  Future<AuthActionResponse> forgotPassword(ForgotPasswordRequest request) {
    return _postMessage(
      path: ApiEndpoints.forgotPassword,
      data: request.toJson(),
      fallbackMessage: 'Unable to send the reset link right now.',
    );
  }

  Future<AuthActionResponse> resetPassword(ResetPasswordRequest request) {
    return _postMessage(
      path: ApiEndpoints.resetPassword,
      data: request.toJson(),
      fallbackMessage: 'Unable to reset your password right now.',
      invalidTokenMessage:
          'This reset link is invalid or has expired. Request a new link and try again.',
    );
  }

  Future<AuthActionResponse> _postMessage({
    required String path,
    required Map<String, dynamic> data,
    required String fallbackMessage,
    String? invalidTokenMessage,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw AuthServiceException(fallbackMessage);
      }

      final parsedResponse = AuthActionResponse.fromJson(responseData);
      if (!parsedResponse.success) {
        throw AuthServiceException(
          _extractErrorMessage(
            responseData,
            statusCode: response.statusCode,
            fallbackMessage: fallbackMessage,
            invalidTokenMessage: invalidTokenMessage,
          ),
          isInvalidToken: _isInvalidTokenStatus(response.statusCode),
        );
      }

      return parsedResponse;
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AuthService DioException path=$path '
          'type=${error.type} '
          'status=${error.response?.statusCode} '
          'data=${error.response?.data} '
          'msg=${error.message}',
        );
      }
      throw AuthServiceException(
        _extractErrorMessage(
          error.response?.data,
          statusCode: error.response?.statusCode,
          fallbackMessage: fallbackMessage,
          invalidTokenMessage: invalidTokenMessage,
          dioException: error,
        ),
        isInvalidToken: _isInvalidTokenStatus(error.response?.statusCode),
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('AuthService unexpected error path=$path: $error\n$stack');
      }
      rethrow;
    }
  }

  String _extractErrorMessage(
    dynamic responseData, {
    required String fallbackMessage,
    int? statusCode,
    String? invalidTokenMessage,
    DioException? dioException,
  }) {
    if (_isInvalidTokenStatus(statusCode) && invalidTokenMessage != null) {
      return invalidTokenMessage;
    }

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      final nestedMessage = data is Map<String, dynamic>
          ? data['message']
          : null;
      final directMessage = responseData['message'];
      final errorMessage = responseData['error'];

      for (final candidate in [nestedMessage, directMessage, errorMessage]) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    if (dioException != null &&
        (dioException.type == DioExceptionType.connectionError ||
            dioException.type == DioExceptionType.connectionTimeout ||
            dioException.type == DioExceptionType.receiveTimeout ||
            dioException.type == DioExceptionType.sendTimeout)) {
      return 'Unable to reach the server. Check your connection and try again.';
    }

    if (kDebugMode && statusCode != null) {
      return '$fallbackMessage (HTTP $statusCode)';
    }

    return fallbackMessage;
  }

  bool _isInvalidTokenStatus(int? statusCode) {
    return statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 404 ||
        statusCode == 410;
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message, {this.isInvalidToken = false});

  final String message;
  final bool isInvalidToken;

  @override
  String toString() => message;
}
