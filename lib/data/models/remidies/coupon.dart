enum DiscountType { PERCENTAGE, FIXED }

class Coupon {
  final String id;
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final int maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final String assignedUserId;
  final bool requiresGrant;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxUses,
    required this.usedCount,
    this.expiresAt,
    required this.isActive,
    required this.assignedUserId,
    this.requiresGrant = false,
  });

  int get remainingUses => maxUses - usedCount;

  String get statusLabel {
    if (!isActive) return 'Deactivated';
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return 'Expired';
    if (usedCount >= maxUses) return 'Limit Reached';
    if (requiresGrant) return 'One-time (sent)';
    return 'Active';
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      discountType: json['discountType'] == 'FIXED'
          ? DiscountType.FIXED
          : DiscountType.PERCENTAGE,
      discountValue: _toDouble(json['discountValue']),
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? false,
      assignedUserId: (json['assignedUserId'] ?? json['userId'] ?? '').toString(),
      requiresGrant: json['requiresGrant'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'discountType': discountType.name,
        'discountValue': discountValue,
        'maxUses': maxUses,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'isActive': isActive,
        'assignedUserId': assignedUserId,
        'requiresGrant': requiresGrant,
      };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
