import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/local/storage_service.dart';
import 'api_interceptor.dart';
import 'api_endpoints.dart';

class DioClient {
  final Dio _dio;
  final StorageService storage;

  DioClient._(this._dio, this.storage);

  static Future<DioClient> create(StorageService storage) async {
    final options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);
    dio.interceptors.add(ApiInterceptor(storage));
    if (kDebugMode) {
      dio.interceptors.add(PrettyPrinterInterceptor());
    }

    return DioClient._(dio, storage);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _retry(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _retry(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _retry(() => _dio.put(path, data: data));
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _retry(() => _dio.delete(path, data: data));
  }

  Future<Response> _retry(
    Future<Response> Function() fn, {
    int retries = 2,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final resp = await fn();
        return resp;
      } on DioException catch (e) {
        attempt++;
        final shouldRetry =
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.receiveTimeout) &&
            attempt <= retries;
        if (!shouldRetry) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * 1 << attempt));
      } on SocketException catch (_) {
        attempt++;
        if (attempt > retries) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}

/// Simple pretty printer interceptor used only in debug.
class PrettyPrinterInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('  ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('⚠ ${err.message}');
    super.onError(err, handler);
  }
}
