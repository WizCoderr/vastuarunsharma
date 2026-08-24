import 'package:vastuarunsharma/data/models/remidies/category.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? description;
  final List<String> images;
  final double price;
  final double? rate;
  /// Present on cart nested products; stripped on public catalog.
  final int? stock;
  final bool isActive;
  final Category category;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description,
    this.images = const [],
    required this.price,
    this.rate,
    this.stock,
    required this.isActive,
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  /// First image URL for list/detail widgets that expect a single image.
  String? get image => images.isNotEmpty ? images.first : null;

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryId =
        (json['categoryId'] as String?) ?? (json['category_id'] as String?);
    final categoryRaw = json['category'];
    final Category category = categoryRaw is Map<String, dynamic>
        ? Category.fromJson(categoryRaw)
        : Category(id: categoryId ?? '', name: '');

    final price =
        double.tryParse(json['price']?.toString() ?? '') ??
        double.tryParse(json['rate']?.toString() ?? '') ??
        0.0;
    final rate = json['rate'] != null
        ? double.tryParse(json['rate'].toString())
        : null;

    return Product(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
      categoryId: categoryId ?? category.id,
      description: json['description'] as String?,
      images: _parseImages(json),
      price: price,
      rate: rate,
      stock: _parseStock(json['stock']),
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
      'images': images,
      'price': price,
      if (rate != null) 'rate': rate,
      if (stock != null) 'stock': stock,
      'isActive': isActive,
      'category': category.toJson(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// Only true when stock is known and zero (cart nested product).
  bool get isOutOfStock => stock != null && stock == 0;

  static List<String> _parseImages(Map<String, dynamic> json) {
    final rawImages = json['images'];
    if (rawImages is List) {
      return rawImages
          .map((e) => _normalizeImageUrl(e?.toString()))
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList();
    }
    final single = _normalizeImageUrl(json['image'] as String?);
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  static int? _parseStock(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

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
