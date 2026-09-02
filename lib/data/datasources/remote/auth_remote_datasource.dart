import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/auth_action_exception.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/request/forgot_password_request.dart';
import '../../models/request/reset_password_request.dart';
import '../../models/request/verify_reset_otp_request.dart';
import '../../models/response/auth_action_response.dart';
import '../../models/response/verify_reset_otp_response.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<AuthResponseBlock> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.login}',
        data: {'email': email, 'password': password},
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponseBlock> register(
    String email,
    String password,
    String name,
    String mobileNumber,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.register}',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phoneNumber': mobileNumber,
          'role': 'student', // Default role for app users
        },
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('${ApiEndpoints.baseUrl}${ApiEndpoints.logout}');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.me}',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 401) {
        throw AuthException('Unauthorized');
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == false) {
        throw AuthException('Unauthorized');
      }

      final userData = responseData is Map<String, dynamic>
          ? (responseData['data'] ?? responseData)
          : responseData;
      if (userData is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized');
      }
      throw _handleError(e);
    }
  }

  Future<AuthActionResponse> forgotPassword(ForgotPasswordRequest request) {
    return _postMessage(
      path: ApiEndpoints.forgotPassword,
      data: request.toJson(),
      fallbackMessage: 'Unable to send the reset code right now.',
    );
  }

  Future<VerifyResetOtpResponse> verifyResetOtp(
    VerifyResetOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.verifyResetOtp}',
        data: request.toJson(),
      );
      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw AuthActionException('Unable to verify the reset code right now.');
      }

      final parsedResponse = VerifyResetOtpResponse.fromJson(responseData);
      if (!parsedResponse.success || parsedResponse.resetToken.isEmpty) {
        throw AuthActionException(
          _extractErrorMessage(
            responseData,
            statusCode: response.statusCode,
            fallbackMessage: 'Invalid or expired code. Request a new code and try again.',
            invalidTokenMessage:
                'Invalid or expired code. Request a new code and try again.',
          ),
          isInvalidToken: true,
        );
      }

      return parsedResponse;
    } on DioException catch (error) {
      throw AuthActionException(
        _extractErrorMessage(
          error.response?.data,
          statusCode: error.response?.statusCode,
          fallbackMessage: 'Unable to verify the reset code right now.',
          invalidTokenMessage:
              'Invalid or expired code. Request a new code and try again.',
          dioException: error,
        ),
        isInvalidToken: _isInvalidTokenStatus(error.response?.statusCode),
      );
    }
  }

  Future<AuthActionResponse> resetPassword(ResetPasswordRequest request) {
    return _postMessage(
      path: ApiEndpoints.resetPassword,
      data: request.toJson(),
      fallbackMessage: 'Unable to reset your password right now.',
      invalidTokenMessage:
          'This reset session is invalid or has expired. Request a new code and try again.',
    );
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.profile}',
        data: data,
      );

      final responseData = response.data;
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Update failed');
      }

      final userData = responseData['data'] is Map
          ? responseData['data']
          : responseData;
      return UserModel.fromJson(userData['user'] ?? userData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AuthResponseBlock _parseAuthResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final success =
          data['success'] as bool? ??
          true; // Default to true if not present, adjust based on actual API

      if (!success) {
        throw Exception(
          data['message'] ?? data['error'] ?? 'Authentication failed: $data',
        );
      }

      final responseData = data['data'] ?? data;

      if (responseData == null) throw Exception("Empty response data");

      final token = responseData['token'] as String?;
      final userMap = responseData['user'];

      if (token == null || userMap == null) {
        throw Exception("Invalid response format: missing token or user");
      }

      return AuthResponseBlock(token: token, user: UserModel.fromJson(userMap));
    }
    throw Exception("Invalid response format");
  }

  Future<AuthActionResponse> _postMessage({
    required String path,
    required Map<String, dynamic> data,
    required String fallbackMessage,
    String? invalidTokenMessage,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}$path',
        data: data,
      );
      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw AuthActionException(fallbackMessage);
      }

      final parsedResponse = AuthActionResponse.fromJson(responseData);
      if (!parsedResponse.success) {
        throw AuthActionException(
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
          'AuthRemoteDataSource DioException path=$path '
          'type=${error.type} '
          'status=${error.response?.statusCode} '
          'data=${error.response?.data} '
          'msg=${error.message}',
        );
      }
      throw AuthActionException(
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
        debugPrint(
          'AuthRemoteDataSource unexpected error path=$path: $error\n$stack',
        );
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
      final errorField = responseData['error'];
      final errorMessage = errorField is String
          ? errorField
          : errorField is Map<String, dynamic>
          ? errorField['message']?.toString()
          : null;

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

  Exception _handleError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return Exception(data['message']);
      }
    }
    return Exception(e.message ?? 'Network Error');
  }
}

class AuthResponseBlock {
  final String token;
  final UserModel user;

  AuthResponseBlock({required this.token, required this.user});
}
