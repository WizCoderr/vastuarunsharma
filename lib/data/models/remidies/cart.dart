import 'package:vastuarunsharma/data/models/remidies/cart_item.dart';

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double? serverSubtotal;
  final int? serverItemCount;
  final double? serverBulkDiscount;
  final double? serverTotalBeforeCoupon;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    this.serverSubtotal,
    this.serverItemCount,
    this.serverBulkDiscount,
    this.serverTotalBeforeCoupon,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      userId: (json['userId'] ?? json['user_id'] ?? '') as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      serverSubtotal: json['subtotal'] != null
          ? double.tryParse(json['subtotal'].toString())
          : null,
      serverItemCount: json['itemCount'] != null
          ? int.tryParse(json['itemCount'].toString())
          : null,
      serverBulkDiscount: json['bulkDiscount'] != null
          ? double.tryParse(json['bulkDiscount'].toString())
          : null,
      serverTotalBeforeCoupon: json['totalBeforeCoupon'] != null
          ? double.tryParse(json['totalBeforeCoupon'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      if (serverSubtotal != null) 'subtotal': serverSubtotal,
      if (serverItemCount != null) 'itemCount': serverItemCount,
      if (serverBulkDiscount != null) 'bulkDiscount': serverBulkDiscount,
      if (serverTotalBeforeCoupon != null)
        'totalBeforeCoupon': serverTotalBeforeCoupon,
    };
  }

  int get itemCount => serverItemCount ?? items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      serverSubtotal ??
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get bulkDiscount => serverBulkDiscount ?? 0;

  double get totalBeforeCoupon =>
      serverTotalBeforeCoupon ?? (subtotal - bulkDiscount);

  double get estimatedTotal => totalBeforeCoupon;

  @override
  String toString() {
    return 'Cart(id: $id, userId: $userId, itemCount: $itemCount)';
  }
}
