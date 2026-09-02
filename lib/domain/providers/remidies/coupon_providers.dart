import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/bulk_discount_tier.dart';
import 'package:vastuarunsharma/data/models/remidies/coupon.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

// Student: my assigned coupons
final myCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final repo = ref.watch(remidiesRepositoryProvider);
  return repo.getMyCoupons();
});

// Student: validate a coupon code on demand
final validateCouponProvider =
    FutureProvider.family<Map<String, dynamic>, ({String code, String? phone})>(
        (ref, args) async {
  final repo = ref.read(remidiesRepositoryProvider);
  return repo.validateCoupon(args.code, phoneNumber: args.phone);
});

// Admin: all coupons list
final adminCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final repo = ref.watch(remidiesRepositoryProvider);
  return repo.adminGetCoupons();
});

// Admin: all bulk tiers list
final adminBulkTiersProvider =
    FutureProvider<List<BulkDiscountTier>>((ref) async {
  final repo = ref.watch(remidiesRepositoryProvider);
  return repo.adminGetBulkTiers();
});
