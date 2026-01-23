import 'package:dio/dio.dart';

import '../../models/user_model.dart';
import '../../../core/api/api_endpoints.dart';

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
