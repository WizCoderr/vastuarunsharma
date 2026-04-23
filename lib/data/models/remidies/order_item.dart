import 'package:vastuarunsharma/data/models/remidies/product.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

extension OrderStatusWire on OrderStatus {
  String get wireName => name.toUpperCase();
}

class OrderItem {
  final String id;
  final String productId;
  final int quantity;
  final double price;
  final Product product;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'product': product.toJson(),
    };
  }

  double get totalPrice => price * quantity;

  @override
  String toString() {
    return 'OrderItem(id: $id, productId: $productId, quantity: $quantity)';
  }
}
