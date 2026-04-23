import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/bulk_discount_tier.dart';
import 'package:vastuarunsharma/domain/providers/remidies/coupon_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

class AdminBulkTiersScreen extends ConsumerWidget {
  const AdminBulkTiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(adminBulkTiersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF985000),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bulk Discount Tiers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD7A417),
        foregroundColor: Colors.white,
        onPressed: () => _showTierForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Tier'),
      ),
      body: tiersAsync.when(
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
                onPressed: () => ref.invalidate(adminBulkTiersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tiers) => tiers.isEmpty
            ? const Center(
                child: Text(
                  'No bulk tiers yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tiers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TierTile(
                  tier: tiers[i],
                  onEdit: () => _showTierForm(context, ref, tiers[i]),
                  onDelete: () => _deleteTier(context, ref, tiers[i]),
                  onToggle: (active) => _toggleTier(
                    context,
                    ref,
                    tiers[i],
                    active,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _deleteTier(
    BuildContext context,
    WidgetRef ref,
    BulkDiscountTier tier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tier'),
        content: Text('Delete tier "${tier.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(remidiesRepositoryProvider).adminDeleteBulkTier(tier.id);
      ref.invalidate(adminBulkTiersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tier deleted')),
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

  Future<void> _toggleTier(
    BuildContext context,
    WidgetRef ref,
    BulkDiscountTier tier,
    bool active,
  ) async {
    try {
      await ref.read(remidiesRepositoryProvider).adminUpdateBulkTier(
            tier.id,
            {'isActive': active},
          );
      ref.invalidate(adminBulkTiersProvider);
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

  Future<void> _showTierForm(
    BuildContext context,
    WidgetRef ref,
    BulkDiscountTier? existing,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TierFormSheet(existing: existing, ref: ref),
    );
  }
}

class _TierTile extends StatelessWidget {
  final BulkDiscountTier tier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _TierTile({
    required this.tier,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tier.type == BulkTierType.QUANTITY
                        ? const Color(0xFF985000).withValues(alpha: 0.1)
                        : const Color(0xFFD7A417).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tier.type.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tier.type == BulkTierType.QUANTITY
                          ? const Color(0xFF985000)
                          : const Color(0xFFB3860B),
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: tier.isActive,
                  activeColor: const Color(0xFF985000),
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tier.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F3200),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tier.type == BulkTierType.QUANTITY
                  ? 'Min. ${tier.minThreshold.toInt()} items required'
                  : 'Min. ₹${_fmt(tier.minThreshold)} order value',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    final str = v.toInt().toString();
    if (str.length <= 3) return str;
    return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
  }
}

class _TierFormSheet extends StatefulWidget {
  final BulkDiscountTier? existing;
  final WidgetRef ref;

  const _TierFormSheet({required this.existing, required this.ref});

  @override
  State<_TierFormSheet> createState() => _TierFormSheetState();
}

class _TierFormSheetState extends State<_TierFormSheet> {
  final _thresholdCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  String _type = 'QUANTITY';
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _thresholdCtrl.text = t.minThreshold.toString();
      _discountCtrl.text = t.discountPercent.toString();
      _type = t.type.name;
      _isActive = t.isActive;
    }
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final threshold = double.tryParse(_thresholdCtrl.text.trim()) ?? 0;
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;

    if (threshold <= 0 || discount <= 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid threshold and discount (1-100%)'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = widget.ref.read(remidiesRepositoryProvider);
      if (widget.existing == null) {
        await repo.adminCreateBulkTier(
          type: _type,
          minThreshold: threshold,
          discountPercent: discount,
        );
      } else {
        await repo.adminUpdateBulkTier(widget.existing!.id, {
          'type': _type,
          'minThreshold': threshold,
          'discountPercent': discount,
          'isActive': _isActive,
        });
      }
      widget.ref.invalidate(adminBulkTiersProvider);
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
    final thresholdHint = _type == 'QUANTITY'
        ? 'Min. quantity (e.g. 5 items)'
        : 'Min. order value in ₹ (e.g. 5000)';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
            isEdit ? 'Edit Bulk Tier' : 'Create Bulk Tier',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F3200),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: _deco('Tier Type'),
            items: const [
              DropdownMenuItem(value: 'QUANTITY', child: Text('Quantity (item count)')),
              DropdownMenuItem(value: 'VALUE', child: Text('Value (order amount ₹)')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: _deco('Min. Threshold').copyWith(hintText: thresholdHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discountCtrl,
            keyboardType: TextInputType.number,
            decoration: _deco('Discount Percent (%)'),
          ),
          if (isEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Active'),
                const Spacer(),
                Switch(
                  value: _isActive,
                  activeColor: const Color(0xFF985000),
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
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
                  : Text(isEdit ? 'Update Tier' : 'Create Tier'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label) {
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
