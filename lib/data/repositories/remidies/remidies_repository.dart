import 'package:dio/dio.dart';
import 'package:vastuarunsharma/data/models/remidies/cart.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/data/models/remidies/order.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';

class RemidiesRepository {
  final Dio dio;
  final String baseUrl = 'https://api.vastuarunsharma.com/api/student/remidies';

  RemidiesRepository({required this.dio});

  // Helper method to add auth token
  Future<String> _getAuthToken() async {
    // TODO: Get token from existing auth token storage
    return 'your_token_here';
  }

  // Categories API
  Future<List<Category>> getCategories() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        '$baseUrl/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load categories');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading categories',
      );
    }
  }

  // Products API
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    bool isActive = true,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        '$baseUrl/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          'isActive': isActive,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final List<dynamic> products = data['products'] ?? [];
        return {
          'products': products
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList(),
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load products');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error loading products',
      );
    }
  }

  // Cart API
  Future<Cart> getCart() async {
    try {
      final token = await _getAuthToken();
      final response = await dio.get(
        '$baseUrl/cart',
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
        '$baseUrl/cart',
        data: {'productId': productId, 'quantity': quantity},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add to cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error adding to cart',
      );
    }
  }

  Future<Cart> updateCartItem(String productId, int quantity) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.put(
        '$baseUrl/cart/$productId',
        data: {'quantity': quantity},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error updating cart',
      );
    }
  }

  Future<Cart> removeCartItem(String productId) async {
    try {
      final token = await _getAuthToken();
      final response = await dio.delete(
        '$baseUrl/cart/$productId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to remove from cart');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Network error removing from cart',
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
        '$baseUrl/orders',
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
        '$baseUrl/orders',
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
}
