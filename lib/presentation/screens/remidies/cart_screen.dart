import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/cart_item.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  // Stitch design tokens
  static const Color _background = Color(0xFFF9F9F9);
  static const Color _primary = Color(0xFF984624);
  static const Color _primaryContainer = Color(0xFFF28C64);
  static const Color _surfaceLowest = Color(0xFFFFFFFF);
  static const Color _surfaceLow = Color(0xFFF3F3F3);
  static const Color _surfaceContainer = Color(0xFFEEEEEE);
  static const Color _tertiary = Color(0xFF006A64);
  static const Color _tertiaryContainer = Color(0xFF2FB9AF);
  static const Color _onSurface = Color(0xFF1A1C1C);
  static const Color _onSurfaceVariant = Color(0xFF55433C);
  static const Color _outlineVariant = Color(0xFFDBC1B8);

  static const LinearGradient _sunriseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _primaryContainer],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: _background,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: _primary),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _primary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert, color: _primary),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading cart: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        data: (cart) {
          final subtotal = cart.subtotal;
          if (cart.items.isEmpty) {
            return const _EmptyCart();
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildEditorialHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _CartItemCard(item: cart.items[i]),
                ),
              ),
              SliverToBoxAdapter(child: _buildSummary(subtotal)),
              SliverToBoxAdapter(child: _buildCheckout(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVIEW YOUR SELECTION',
            style: TextStyle(
              color: _onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Items for Harmony',
            style: TextStyle(
              color: _onSurface,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double subtotal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CART SUMMARY',
            style: TextStyle(
              color: _onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow('Subtotal', '₹${_fmt(subtotal)}'),
          const SizedBox(height: 10),
          _summaryRow('Standard Shipping', 'FREE', valueColor: _tertiary),
          const SizedBox(height: 14),
          Container(height: 1, color: _outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Total',
                style: TextStyle(
                  color: _onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${_fmt(subtotal)}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _sunriseGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'SECURE ENCRYPTED TRANSACTION',
            style: TextStyle(
              color: _onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0 && fromEnd > 1) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: CartScreen._onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add remedies to begin your journey',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends ConsumerStatefulWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  ConsumerState<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<_CartItemCard> {
  int? _optimisticQty;
  bool _busy = false;

  int get _displayQty => _optimisticQty ?? widget.item.quantity;

  Future<void> _setQuantity(int newQty) async {
    if (_busy) return;
    final productId = widget.item.productId.isNotEmpty
        ? widget.item.productId
        : widget.item.product.id;
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing product id for cart item')),
      );
      return;
    }

    final repo = ref.read(remidiesRepositoryProvider);
    setState(() {
      _optimisticQty = newQty;
      _busy = true;
    });
    try {
      if (newQty <= 0) {
        await repo.removeCartItem(productId);
      } else {
        await repo.updateCartItem(productId, newQty);
      }
      ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
        setState(() => _optimisticQty = null);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final productId = widget.item.productId.isNotEmpty
        ? widget.item.productId
        : widget.item.product.id;
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing product id for cart item')),
      );
      return;
    }

    setState(() {
      _optimisticQty = 0;
      _busy = true;
    });
    try {
      await ref.read(remidiesRepositoryProvider).removeCartItem(productId);
      ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item: $e')),
        );
        setState(() => _optimisticQty = null);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final qty = _displayQty;
    final lineTotal = item.product.price * qty;
    return Opacity(
      opacity: _busy ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CartScreen._surfaceLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildImage(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.product.category.name.isNotEmpty) ...[
                              Text(
                                item.product.category.name.toUpperCase(),
                                style: const TextStyle(
                                  color: CartScreen._primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                color: CartScreen._onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _busy ? null : _delete,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: CartScreen._onSurfaceVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _QtyPill(
                        quantity: qty,
                        disabled: _busy,
                        onMinus: () => _setQuantity(qty - 1),
                        onPlus: () => _setQuantity(qty + 1),
                      ),
                      Text(
                        '₹${CartScreen._fmt(lineTotal)}',
                        style: const TextStyle(
                          color: CartScreen._primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: CartScreen._surfaceContainer,
              width: 88,
              height: 88,
              child: CachedNetworkImage(
                imageUrl: widget.item.product.image ?? '',
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: CartScreen._surfaceContainer),
                errorWidget: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CartScreen._tertiaryContainer.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyPill extends StatelessWidget {
  final int quantity;
  final bool disabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QtyPill({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CartScreen._surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove, disabled ? null : onMinus),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CartScreen._onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _qtyButton(Icons.add, disabled ? null : onPlus),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? CartScreen._onSurface.withValues(alpha: 0.3)
                : CartScreen._onSurface,
          ),
        ),
      ),
    );
  }
}
