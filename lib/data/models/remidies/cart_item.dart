import 'package:vastuarunsharma/data/models/remidies/product.dart';

class CartItem {
  final String id;
  final String cartId;
  final String productId;
  final int quantity;
  final Product product;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    return CartItem(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      cartId: (json['cartId'] ?? json['cart_id'] ?? '') as String,
      productId:
          (json['productId'] ?? json['product_id'] ??
                  (productJson is Map ? productJson['id'] : null) ??
                  '')
              as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      product: productJson is Map<String, dynamic>
          ? Product.fromJson(productJson)
          : Product.fromJson(const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'productId': productId,
      'quantity': quantity,
      'product': product.toJson(),
    };
  }

  double get totalPrice => product.price * quantity;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, quantity: $quantity)';
  }
}
