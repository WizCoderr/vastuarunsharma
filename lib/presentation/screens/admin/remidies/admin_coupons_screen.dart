import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vastuarunsharma/data/models/remidies/coupon.dart';
import 'package:vastuarunsharma/domain/providers/remidies/coupon_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF985000),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Coupon Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD7A417),
        foregroundColor: Colors.white,
        onPressed: () => _showCouponForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Coupon'),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(e.toString().replaceFirst('Exception: ', '')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminCouponsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (coupons) => coupons.isEmpty
            ? const Center(
                child: Text(
                  'No coupons yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: coupons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CouponTile(
                  coupon: coupons[i],
                  onEdit: () => _showCouponForm(context, ref, coupons[i]),
                  onDelete: () => _deleteCoupon(context, ref, coupons[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _deleteCoupon(
    BuildContext context,
    WidgetRef ref,
    Coupon coupon,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Coupon'),
        content: Text('Deactivate coupon "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(remidiesRepositoryProvider).adminDeleteCoupon(coupon.id);
      ref.invalidate(adminCouponsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deactivated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCouponForm(
    BuildContext context,
    WidgetRef ref,
    Coupon? existing,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CouponFormSheet(existing: existing, ref: ref),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CouponTile({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (coupon.statusLabel) {
      'Active' => Colors.green,
      'Expired' => Colors.grey,
      'Limit Reached' => Colors.orange,
      _ => Colors.red,
    };

    final discountLabel = coupon.discountType == DiscountType.PERCENTAGE
        ? '${coupon.discountValue.toStringAsFixed(coupon.discountValue == coupon.discountValue.truncateToDouble() ? 0 : 1)}% off'
        : '₹${coupon.discountValue.toStringAsFixed(coupon.discountValue == coupon.discountValue.truncateToDouble() ? 0 : 2)} off';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF4F3200),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    coupon.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              discountLabel,
              style: const TextStyle(
                color: Color(0xFFD7A417),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'User: ${coupon.assignedUserId}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${coupon.usedCount}/${coupon.maxUses} uses',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Expires ${DateFormat('dd MMM yyyy').format(coupon.expiresAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF985000),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.block_outlined, size: 16),
                  label: const Text('Deactivate'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponFormSheet extends StatefulWidget {
  final Coupon? existing;
  final WidgetRef ref;

  const _CouponFormSheet({required this.existing, required this.ref});

  @override
  State<_CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<_CouponFormSheet> {
  final _codeCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();

  String _discountType = 'PERCENTAGE';
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _codeCtrl.text = c.code;
      _discountValueCtrl.text = c.discountValue.toString();
      _maxUsesCtrl.text = c.maxUses.toString();
      _userIdCtrl.text = c.assignedUserId;
      _discountType = c.discountType.name;
      _expiresAt = c.expiresAt;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountValueCtrl.dispose();
    _maxUsesCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final discountValue = double.tryParse(_discountValueCtrl.text.trim()) ?? 0;
    final maxUses = int.tryParse(_maxUsesCtrl.text.trim()) ?? 0;
    final userId = _userIdCtrl.text.trim();

    if (code.isEmpty || discountValue <= 0 || maxUses <= 0 || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = widget.ref.read(remidiesRepositoryProvider);
      if (widget.existing == null) {
        await repo.adminCreateCoupon(
          code: code,
          discountType: _discountType,
          discountValue: discountValue,
          maxUses: maxUses,
          expiresAt: _expiresAt,
          assignedUserId: userId,
        );
      } else {
        await repo.adminUpdateCoupon(widget.existing!.id, {
          'code': code,
          'discountType': _discountType,
          'discountValue': discountValue,
          'maxUses': maxUses,
          'expiresAt': _expiresAt.toIso8601String(),
          'assignedUserId': userId,
        });
      }
      widget.ref.invalidate(adminCouponsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Coupon' : 'Create Coupon',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F3200),
              ),
            ),
            const SizedBox(height: 16),
            _field('Coupon Code', _codeCtrl),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _discountType,
              decoration: _inputDecoration('Discount Type'),
              items: const [
                DropdownMenuItem(
                  value: 'PERCENTAGE',
                  child: Text('Percentage (%)'),
                ),
                DropdownMenuItem(
                  value: 'FIXED',
                  child: Text('Fixed Amount (₹)'),
                ),
              ],
              onChanged: (v) => setState(() => _discountType = v!),
            ),
            const SizedBox(height: 12),
            _field(
              _discountType == 'PERCENTAGE'
                  ? 'Discount Value (%)'
                  : 'Discount Value (₹)',
              _discountValueCtrl,
              type: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field('Max Uses', _maxUsesCtrl, type: TextInputType.number),
            const SizedBox(height: 12),
            _field('Assigned User ID', _userIdCtrl),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _inputDecoration('Expiry Date'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_expiresAt),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7A417),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Update Coupon' : 'Create Coupon'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD7A417)),
      ),
    );
  }
}
