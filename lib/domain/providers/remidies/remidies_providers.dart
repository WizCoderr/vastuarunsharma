import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';
import 'package:vastuarunsharma/data/repositories/remidies/remidies_repository.dart';

// Shared Dio provider
final dioProvider = Provider<Dio>((ref) {
  return Dio();
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

// Products provider with pagination and filtering
final productsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final repository = ref.watch(remidiesRepositoryProvider);
      final page = (params['page'] as int?) ?? 1;
      final limit = (params['limit'] as int?) ?? 20;
      final categoryId = params['categoryId'] as String?;
      return repository.getProducts(
        page: page,
        limit: limit,
        categoryId: categoryId,
        isActive: true,
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
