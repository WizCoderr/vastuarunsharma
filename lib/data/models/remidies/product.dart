import 'package:vastuarunsharma/data/models/remidies/category.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? description;
  final String? image;
  final double price;
  final int stock;
  final bool isActive;
  final Category category;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description,
    this.image,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'image': image,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      'category': category.toJson(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  bool get isOutOfStock => stock == 0;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price)';
  }
}
