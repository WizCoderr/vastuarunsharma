import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/cart.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

// Cart provider
final cartProvider = FutureProvider<Cart>((ref) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  return repository.getCart();
});

// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (cart) => cart.totalQuantity,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

// Add to cart provider
final addToCartProvider = FutureProvider.family<Cart, (String, int)>((
  ref,
  params,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  final cart = await repository.addToCart(params.$1, params.$2);
  // Invalidate cart provider to refresh
  ref.invalidate(cartProvider);
  return cart;
});

// Update cart item provider
final updateCartItemProvider = FutureProvider.family<Cart, (String, int)>((
  ref,
  params,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  final cart = await repository.updateCartItem(params.$1, params.$2);
  // Invalidate cart provider to refresh
  ref.invalidate(cartProvider);
  return cart;
});

// Remove cart item provider
final removeCartItemProvider = FutureProvider.family<Cart, String>((
  ref,
  productId,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  final cart = await repository.removeCartItem(productId);
  // Invalidate cart provider to refresh
  ref.invalidate(cartProvider);
  return cart;
});
