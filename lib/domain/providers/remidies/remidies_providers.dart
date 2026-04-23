import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vastuarunsharma/core/api/api_endpoints.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';
import 'package:vastuarunsharma/data/repositories/remidies/remidies_repository.dart';

// Shared Dio provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );
});

// Repository provider
final remidiesRepositoryProvider = Provider<RemidiesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RemidiesRepository(dio: dio);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  return repository.getCategories();
});

// Selected category state provider
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

typedef ProductsParams = ({int page, int limit, String? categoryId});

// Products provider — backend supports categoryId + isActive query params
// on GET /api/student/remidies/products/all
final productsProvider =
    FutureProvider.family<Map<String, dynamic>, ProductsParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(remidiesRepositoryProvider);
      return repository.getProducts(
        page: params.page,
        limit: params.limit,
        categoryId: params.categoryId,
        isActive: true,
      );
    });

// Single product provider
final productProvider = FutureProvider.family<Product, String>((
  ref,
  productId,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  final result = await repository.getProducts(page: 1, limit: 100);
  final products = result['products'] as List<Product>;
  return products.firstWhere(
    (p) => p.id == productId,
    orElse: () => throw Exception('Product not found'),
  );
});

// Filtered products provider (client-side filtering)
final filteredProductsProvider = Provider.family<List<Product>, List<Product>>((
  ref,
  products,
) {
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return products;
  }

  return products
      .where(
        (product) =>
            product.name.toLowerCase().contains(searchQuery) ||
            (product.description?.toLowerCase().contains(searchQuery) ?? false),
      )
      .toList();
});
