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
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('Response: ${response.data}');
    }

    if (response.statusCode == 401) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: AuthException('Unauthorized'),
          response: response,
        ),
      );
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status == 401) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AuthException('Unauthorized'),
          response: err.response,
        ),
      );
    }

    if (status == 429) {
      final data = err.response?.data;
      String message = 'Too many requests. Please wait and try again.';
      if (data is Map) {
        final error = data['error'];
        final bodyMessage = data['message'];
        if (error is String && error.isNotEmpty) {
          message = error;
        } else if (bodyMessage is String && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        }
      }
      final retryAfter = err.response?.headers.value('retry-after');
      if (retryAfter != null && retryAfter.isNotEmpty) {
        message = '$message (Retry after ${retryAfter}s)';
      }
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ServerException(message, status),
          response: err.response,
          type: err.type,
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
        ? (err.response?.data['error'] ??
            err.response?.data['message'] ??
            err.message)
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
