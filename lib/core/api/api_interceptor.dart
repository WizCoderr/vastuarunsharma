import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/local/storage_service.dart';
import '../errors/exceptions.dart';

/// Interceptor to inject auth token, log and handle errors centrally.
class ApiInterceptor extends Interceptor {
  final StorageService storage;
  ApiInterceptor(this.storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ApiInterceptor: failed to read token: $e');
    }

    if (kDebugMode) {
      debugPrint('--> ${options.method} ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      if (options.data != null) debugPrint('Body: ${options.data}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('Response: ${response.data}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status == 401) {
      // token expired or invalid - clear storage and throw AuthException
      try {
        await storage.clearAuth();
      } catch (_) {}
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AuthException('Unauthorized'),
          response: err.response,
        ),
      );
    }

    if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(err.message ?? 'Network error'),
        ),
      );
    }

    // For other HTTP errors, wrap as ServerException with status
    final message = err.response?.data is Map
        ? (err.response?.data['message'] ?? err.message)
        : err.message;
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ServerException(message?.toString() ?? 'Server error', status),
        response: err.response,
      ),
    );
  }
}
