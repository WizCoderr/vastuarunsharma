enum BulkTierType { QUANTITY, VALUE }

class BulkDiscountTier {
  final String id;
  final BulkTierType type;
  final double minThreshold;
  final double discountPercent;
  final bool isActive;

  BulkDiscountTier({
    required this.id,
    required this.type,
    required this.minThreshold,
    required this.discountPercent,
    required this.isActive,
  });

  String get label {
    final pct = discountPercent.toStringAsFixed(
        discountPercent == discountPercent.truncateToDouble() ? 0 : 1);
    if (type == BulkTierType.QUANTITY) {
      return '$pct% off for ${minThreshold.toInt()}+ items';
    } else {
      return '$pct% off for orders ₹${_fmt(minThreshold)}+';
    }
  }

  factory BulkDiscountTier.fromJson(Map<String, dynamic> json) {
    return BulkDiscountTier(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: json['type'] == 'VALUE' ? BulkTierType.VALUE : BulkTierType.QUANTITY,
      minThreshold: _toDouble(json['minThreshold']),
      discountPercent: _toDouble(json['discountPercent']),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'minThreshold': minThreshold,
        'discountPercent': discountPercent,
        'isActive': isActive,
      };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String _fmt(double v) {
    final str = v.toInt().toString();
    if (str.length <= 3) return str;
    return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
  }
}
