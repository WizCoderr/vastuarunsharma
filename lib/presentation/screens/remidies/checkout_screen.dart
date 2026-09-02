import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vastuarunsharma/core/constants/route_constants.dart';
import 'package:vastuarunsharma/core/utils/price_format.dart';
import 'package:vastuarunsharma/data/models/remidies/coupon.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/presentation/providers/auth_provider.dart';
import 'package:vastuarunsharma/domain/providers/remidies/coupon_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/order_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isValidatingCoupon = false;
  bool _isPlacingOrder = false;
  String? _couponError;
  String? _couponSuccess;
  double _couponDiscountAmount = 0;
  double? _pricingBulkDiscount;
  String? _appliedCouponCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      final mobile = user?.mobileNumber?.trim();
      if (mobile != null && mobile.isNotEmpty && _phoneNumberController.text.isEmpty) {
        setState(() => _phoneNumberController.text = mobile);
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon([String? codeOverride]) async {
    final code = (codeOverride ?? _couponController.text).trim();
    if (code.isEmpty) return;

    if (codeOverride != null) {
      _couponController.text = code;
    }

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
      _couponSuccess = null;
    });

    try {
      final result = await ref.read(remidiesRepositoryProvider).validateCoupon(
            code,
            phoneNumber: _phoneNumberController.text.trim(),
          );

      final discountAmount = _parseDouble(result['discountAmount']);
      final bulkDiscount = result['bulkDiscount'] != null
          ? _parseDouble(result['bulkDiscount'])
          : null;

      setState(() {
        _appliedCouponCode = code;
        _couponDiscountAmount = discountAmount;
        _pricingBulkDiscount = bulkDiscount;
        _couponSuccess = result['message']?.toString() ??
            'Coupon applied successfully!';
        _couponError = null;
      });
    } catch (e) {
      setState(() {
        _appliedCouponCode = null;
        _couponDiscountAmount = 0;
        _pricingBulkDiscount = null;
        _couponError = e.toString().replaceFirst('Exception: ', '');
        _couponSuccess = null;
      });
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponDiscountAmount = 0;
      _pricingBulkDiscount = null;
      _couponError = null;
      _couponSuccess = null;
      _couponController.clear();
    });
  }

  Future<void> _placeOrder() async {
    final formData = CheckoutFormData(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      couponCode: _appliedCouponCode,
    );

    if (!formData.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final result = await ref
          .read(remidiesRepositoryProvider)
          .checkout(
            fullName: formData.fullName,
            phoneNumber: formData.phoneNumber,
            address: formData.address,
            city: formData.city,
            state: formData.state,
            postalCode: formData.postalCode,
            couponCode: formData.couponCode,
          );

      // Prefer data.order.id from checkout envelope
      final order = result['order'];
      final orderId = (order is Map
              ? (order['id'] ?? order['_id'])
              : null) ??
          result['_id'] ??
          result['id'] ??
          result['orderId'] ??
          '';
      final orderIdStr = orderId.toString();

      if (!mounted) return;
      if (orderIdStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created but payment id missing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ref.invalidate(cartProvider);
      context.push(RouteConstants.remediesPaymentPath, extra: orderIdStr);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7A417),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _fullNameController),
              const SizedBox(height: 12),
              _buildTextField(
                'Phone Number',
                _phoneNumberController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField('Address', _addressController),
              const SizedBox(height: 12),
              _buildTextField('City', _cityController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('State', _stateController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'Postal Code',
                      _postalCodeController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCouponSection(),
              const SizedBox(height: 20),
              _PriceBreakdownCard(
                appliedCouponCode: _appliedCouponCode,
                couponDiscountAmount: _couponDiscountAmount,
                pricingBulkDiscount: _pricingBulkDiscount,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFD3C5AE).withValues(alpha: 0.3),
            ),
          ),
        ),
        child: GestureDetector(
          onTap: _isPlacingOrder ? null : _placeOrder,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isPlacingOrder
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [const Color(0xFFD7A417), const Color(0xFFB3860B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD7A417).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Place Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    final myCouponsAsync = ref.watch(myCouponsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myCouponsAsync.when(
          data: (coupons) {
            if (coupons.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your coupons',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1C19),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coupons.map((coupon) {
                    final label = coupon.discountType == DiscountType.PERCENTAGE
                        ? '${coupon.code} · ${coupon.discountValue.toStringAsFixed(coupon.discountValue == coupon.discountValue.truncateToDouble() ? 0 : 1)}% off'
                        : '${coupon.code} · ₹${coupon.discountValue.toStringAsFixed(0)} off';
                    final isApplied = _appliedCouponCode?.toUpperCase() ==
                        coupon.code.toUpperCase();

                    return ActionChip(
                      label: Text(label),
                      backgroundColor: isApplied
                          ? const Color(0xFFD7A417).withValues(alpha: 0.2)
                          : const Color(0xFFF5F0E6),
                      side: BorderSide(
                        color: isApplied
                            ? const Color(0xFFD7A417)
                            : const Color(0xFFD3C5AE),
                      ),
                      onPressed: (_isValidatingCoupon || isApplied)
                          ? null
                          : () => _applyCoupon(coupon.code),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const Text(
          'Coupon Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1C19),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                'Enter Coupon Code',
                _couponController,
                enabled: _appliedCouponCode == null,
              ),
            ),
            const SizedBox(width: 8),
            _appliedCouponCode != null
                ? IconButton(
                    onPressed: _removeCoupon,
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Remove coupon',
                  )
                : TextButton(
                    onPressed: _isValidatingCoupon ? null : _applyCoupon,
                    child: _isValidatingCoupon
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD7A417),
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              color: Color(0xFFD7A417),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
          ],
        ),
        if (_couponSuccess != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _couponSuccess!,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (_couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _couponError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.amber),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class _PriceBreakdownCard extends ConsumerWidget {
  final String? appliedCouponCode;
  final double couponDiscountAmount;
  final double? pricingBulkDiscount;

  const _PriceBreakdownCard({
    required this.appliedCouponCode,
    required this.couponDiscountAmount,
    required this.pricingBulkDiscount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final pricing = cartAsync.when(
      data: (cart) => (
        subtotal: cart.subtotal,
        bulkDiscount: pricingBulkDiscount ?? cart.bulkDiscount,
      ),
      loading: () => (subtotal: 0.0, bulkDiscount: 0.0),
      error: (_, _) => (subtotal: 0.0, bulkDiscount: 0.0),
    );

    final subtotal = pricing.subtotal;
    final bulkDiscount = pricing.bulkDiscount;
    final couponDiscount =
        appliedCouponCode != null ? couponDiscountAmount : 0.0;
    final total = (subtotal - bulkDiscount - couponDiscount)
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Order Summary',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F4634)),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow('Subtotal', formatInr(subtotal)),
          if (bulkDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              'Bulk Discount',
              '-${formatInr(bulkDiscount)}',
              valueColor: Colors.green,
            ),
          ],
          const SizedBox(height: 8),
          const _SummaryRow('Shipping', 'Free', valueColor: Colors.green),
          if (couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              'Coupon Discount',
              '-${formatInr(couponDiscount)}',
              valueColor: Colors.green,
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formatInr(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD7A417),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: valueColor != null ? TextStyle(color: valueColor) : null,
        ),
      ],
    );
  }
}
