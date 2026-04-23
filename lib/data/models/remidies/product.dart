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
    final categoryId =
        (json['categoryId'] as String?) ?? (json['category_id'] as String?);
    final categoryRaw = json['category'];
    final Category category = categoryRaw is Map<String, dynamic>
        ? Category.fromJson(categoryRaw)
        : Category(id: categoryId ?? '', name: '');

    return Product(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
      categoryId: categoryId ?? category.id,
      description: json['description'] as String?,
      image: _normalizeImageUrl(json['image'] as String?),
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      category: category,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
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

  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    const s3Host = 'https://vastu-prod-data.s3.amazonaws.com/';
    const cdnHost = 'https://d31m2t02kxia5f.cloudfront.net/';
    if (url.startsWith(s3Host)) {
      return cdnHost + url.substring(s3Host.length);
    }
    return url;
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price)';
  }
}
