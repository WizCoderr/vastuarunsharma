import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:vastuarunsharma/core/api/api_endpoints.dart';
import 'package:vastuarunsharma/data/local/storage_service.dart';
import 'package:vastuarunsharma/data/models/remidies/bulk_discount_tier.dart';
import 'package:vastuarunsharma/data/models/remidies/cart.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/data/models/remidies/coupon.dart';
import 'package:vastuarunsharma/data/models/remidies/order.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';

class RemidiesRepository {
  final Dio dio;

  RemidiesRepository({required this.dio});

  // Helper method to add auth token
  Future<String> _getAuthToken() async {
    final storage = await StorageService.init();
    final token = storage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing');
    }
    return token;
  }

  // Categories API (public — no auth)
  Future<List<Category>> getCategories() async {
    try {
      final response = await dio.get(ApiEndpoints.remidiesCategories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          response.data['error'] ??
              response.data['message'] ??
              'Failed to load categories',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error loading categories',
      );
    }
  }

  /// Full catalog via `/products/all`, or paged via `/products`.
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    bool fetchAll = true,
  }) async {
    try {
      final path = fetchAll
          ? ApiEndpoints.remidiesProductsAll
          : ApiEndpoints.remidiesProducts;
      final queryParameters = <String, dynamic>{
        if (!fetchAll) ...{'page': page, 'limit': limit},
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
      };

      final response = await dio.get(
        path,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      developer.log(
        'GET products status=${response.statusCode} '
        'categoryId=$categoryId body=${response.data}',
        name: 'RemidiesRepo',
      );
      if (response.statusCode == 200) {
        final body = response.data;
        final raw = body is Map ? body['data'] : null;
        List<dynamic> productList;
        int total;
        int resPage;
        int resLimit;
        int? totalPages;

        if (raw is Map<String, dynamic>) {
          productList = (raw['products'] as List<dynamic>?) ?? const [];
          total = (raw['total'] as num?)?.toInt() ?? productList.length;
          resPage = (raw['page'] as num?)?.toInt() ?? page;
          resLimit = (raw['limit'] as num?)?.toInt() ?? limit;
        } else if (raw is List<dynamic>) {
          productList = raw;
          final meta = body is Map ? body['meta'] : null;
          if (meta is Map<String, dynamic>) {
            total = (meta['total'] as num?)?.toInt() ?? productList.length;
            resPage = (meta['page'] as num?)?.toInt() ?? page;
            resLimit = (meta['limit'] as num?)?.toInt() ?? limit;
            totalPages = (meta['totalPages'] as num?)?.toInt();
          } else {
            total = (body is Map ? body['total'] as num? : null)?.toInt() ??
                productList.length;
            resPage = page;
            resLimit = limit;
          }
        } else {
          productList = const [];
          total = 0;
          resPage = page;
          resLimit = limit;
        }

        return {
          'products': productList
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList(),
          'total': total,
          'page': resPage,
          'limit': resLimit,
          'totalPages': ?totalPages,
        };
      } else {
        throw Exception(
          response.data['error'] ??
              response.data['message'] ??
              'Failed to load products',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error loading products',
      );
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.remidiesProduct(id));

      if (response.statusCode == 200) {
        final raw = response.data['data'] ?? response.data;
        return Product.fromJson(raw as Map<String, dynamic>);
      } else {
        throw Exception(
          response.data['error'] ??
              response.data['message'] ??
              'Failed to load product',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error loading product',
      );
    }
  }

  // Cart API
  Future<Cart> getCart() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        ApiEndpoints.remidiesCart,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading cart',
      );
    }
  }

  Future<Cart> addToCart(String productId, int quantity) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.post(
        ApiEndpoints.remidiesCart,
        data: <String, dynamic>{
          'productId': productId,
          'quantity': quantity,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Authorization': 'Bearer $token',
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        final err = response.data is Map
            ? (response.data['error'] ?? response.data['message'])
            : response.data;
        throw Exception(err ?? 'Failed to add to cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error adding to cart',
      );
    }
  }

  Future<Cart> updateCartItem(String productId, int quantity) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.put(
        ApiEndpoints.remidiesCartItem(productId),
        data: <String, dynamic>{'quantity': quantity},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Authorization': 'Bearer $token',
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        final err = response.data is Map
            ? (response.data['error'] ?? response.data['message'])
            : response.data;
        throw Exception(err ?? 'Failed to update cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error updating cart',
      );
    }
  }

  Future<Cart> removeCartItem(String productId) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.delete(
        ApiEndpoints.remidiesCartItem(productId),
        // Production still validates DELETE with updateCartItemSchema (quantity >= 1)
        // until the removeCartItemSchema deploy lands. Body is ignored by removeFromCart.
        data: <String, dynamic>{'quantity': 1},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Authorization': 'Bearer $token',
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to remove from cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error removing from cart',
      );
    }
  }

  // Orders API
  Future<Order> createOrder({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String city,
    required String state,
    required String postalCode,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.post(
        ApiEndpoints.remidiesOrders,
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'address': address,
          'city': city,
          'state': state,
          'postalCode': postalCode,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Order.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create order');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error creating order',
      );
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        ApiEndpoints.remidiesOrders,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load orders');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading orders',
      );
    }
  }

  // ── Student Coupon API ────────────────────────────────────────────────────

  Future<List<Coupon>> getMyCoupons() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        ApiEndpoints.remidiesCoupons,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => Coupon.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load coupons');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading coupons',
      );
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
    String couponCode, {
    String? phoneNumber,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.post(
        ApiEndpoints.remidiesValidateCoupon,
        data: {
          'couponCode': couponCode,
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            'phoneNumber': phoneNumber.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return (response.data['data'] ?? response.data) as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data['error'] ??
              response.data['message'] ??
              'Invalid coupon',
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['error'] ?? data['message'])
          : null;
      throw Exception(message?.toString() ?? 'Network error validating coupon');
    }
  }

  Future<Map<String, dynamic>> checkout({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String city,
    required String state,
    required String postalCode,
    String? couponCode,
  }) async {
    try {
      final token = await _getAuthToken();
      final body = <String, dynamic>{
        'shippingName': fullName,
        'shippingPhone': phoneNumber,
        'shippingAddress': address,
        'shippingCity': city,
        'shippingState': state,
        'shippingPostal': postalCode,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
      };
      final response = await dio.post(
        ApiEndpoints.remidiesCheckout,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data['data'] ?? response.data;
        return raw as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data['error'] ??
              response.data['message'] ??
              'Failed to place order',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ??
            e.response?.data['message'] ??
            'Network error placing order',
      );
    }
  }

  // ── Admin Coupon API ──────────────────────────────────────────────────────

  Future<List<Coupon>> adminGetCoupons() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        ApiEndpoints.adminRemidiesCoupons,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => Coupon.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load coupons');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading coupons',
      );
    }
  }

  Future<Coupon> adminCreateCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required int maxUses,
    required DateTime expiresAt,
    required String assignedUserId,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.post(
        ApiEndpoints.adminRemidiesCoupons,
        data: {
          'code': code,
          'discountType': discountType,
          'discountValue': discountValue,
          'maxUses': maxUses,
          'expiresAt': expiresAt.toIso8601String(),
          'assignedUserId': assignedUserId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Coupon.fromJson(
          (response.data['data'] ?? response.data) as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create coupon');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error creating coupon',
      );
    }
  }

  Future<Coupon> adminUpdateCoupon(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.put(
        ApiEndpoints.adminRemidiesCoupon(id),
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return Coupon.fromJson(
          (response.data['data'] ?? response.data) as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update coupon');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error updating coupon',
      );
    }
  }

  Future<void> adminDeleteCoupon(String id) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.delete(
        ApiEndpoints.adminRemidiesCoupon(id),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to deactivate coupon');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error deactivating coupon',
      );
    }
  }

  // ── Admin Bulk Tier API ───────────────────────────────────────────────────

  Future<List<BulkDiscountTier>> adminGetBulkTiers() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        ApiEndpoints.adminRemidiesBulkTiers,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map(
              (json) =>
                  BulkDiscountTier.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load bulk tiers');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading bulk tiers',
      );
    }
  }

  Future<BulkDiscountTier> adminCreateBulkTier({
    required String type,
    required double minThreshold,
    required double discountPercent,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.post(
        ApiEndpoints.adminRemidiesBulkTiers,
        data: {
          'type': type,
          'minThreshold': minThreshold,
          'discountPercent': discountPercent,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BulkDiscountTier.fromJson(
          (response.data['data'] ?? response.data) as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create tier');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error creating tier',
      );
    }
  }

  Future<BulkDiscountTier> adminUpdateBulkTier(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.put(
        ApiEndpoints.adminRemidiesBulkTier(id),
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return BulkDiscountTier.fromJson(
          (response.data['data'] ?? response.data) as Map<String, dynamic>,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update tier');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error updating tier',
      );
    }
  }

  Future<void> adminDeleteBulkTier(String id) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.delete(
        ApiEndpoints.adminRemidiesBulkTier(id),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to delete tier');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error deleting tier',
      );
    }
  }
}
