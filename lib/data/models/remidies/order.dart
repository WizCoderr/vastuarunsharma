import 'package:vastuarunsharma/data/models/remidies/order_item.dart';

export 'package:vastuarunsharma/data/models/remidies/order_item.dart'
    show OrderStatus;

class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String state;
  final String postalCode;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: _parseOrderStatus(json['status'] as String),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'totalAmount': totalAmount,
      'status': status.name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
    };
  }

  static OrderStatus _parseOrderStatus(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.PENDING,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Pending';
      case OrderStatus.PAID:
        return 'Paid';
      case OrderStatus.SHIPPED:
        return 'Shipped';
      case OrderStatus.DELIVERED:
        return 'Delivered';
      case OrderStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, totalAmount: $totalAmount)';
  }
}
