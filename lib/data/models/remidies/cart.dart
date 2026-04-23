import 'package:vastuarunsharma/data/models/remidies/cart_item.dart';

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;

  Cart({required this.id, required this.userId, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      userId: (json['userId'] ?? json['user_id'] ?? '') as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  int get itemCount => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  @override
  String toString() {
    return 'Cart(id: $id, userId: $userId, itemCount: $itemCount)';
  }
}
