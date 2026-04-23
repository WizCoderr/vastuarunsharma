import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/cart_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // Scholar's Gilt palette
  static const Color _primary = Color(0xFF785A00);
  static const Color _primaryContainer = Color(0xFFD7A417);
  static const Color _background = Color(0xFFFAFAF5);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLow = Color(0xFFF4F4EF);
  static const Color _surfaceContainer = Color(0xFFEEEEE9);
  static const Color _onSurface = Color(0xFF1A1C19);
  static const Color _onSurfaceVariant = Color(0xFF4F4634);
  static const Color _secondary = Color(0xFF835425);
  static const Color _outlineVariant = Color(0xFFD3C5AE);

  int _quantity = 1;
  bool _addingToCart = false;

  Future<void> _addToCart(String productId, int stock) async {
    if (_addingToCart) return;
    setState(() => _addingToCart = true);
    try {
      await ref.read(addToCartProvider.call((productId, _quantity)).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final productAsync = ref.watch(productProvider(widget.productId));

    return Scaffold(
      backgroundColor: _background,
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryContainer),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (product) {
          final outOfStock = product.stock == 0;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFFFDFDF8),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: _primaryContainer),
                    ),
                    title: const Text(
                      'Sacred Spaces',
                      style: TextStyle(
                        color: _primaryContainer,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: _primaryContainer,
                            ),
                          ),
                          if (cartItemCount > 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                decoration: const BoxDecoration(
                                  color: _primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartItemCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(0.5),
                      child: Container(
                        height: 0.5,
                        color: _outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero image card
                        _HeroImageCard(imageUrl: product.image ?? ''),
                        const SizedBox(height: 16),

                        // Thumbnail gallery row
                        _ThumbnailGallery(imageUrl: product.image ?? ''),
                        const SizedBox(height: 24),

                        // Breadcrumb
                        Row(
                          children: [
                            Text(
                              product.category.name.toUpperCase(),
                              style: TextStyle(
                                color: _secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF835425),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CURATED SETS',
                              style: TextStyle(
                                color: _secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Product name
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Price + rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹${_formatPrice(product.price)}',
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _Stars(rating: product.rating),
                            const SizedBox(width: 6),
                            Text(
                              '(${product.rating.toStringAsFixed(1)} · ${product.reviewCount} reviews)',
                              style: const TextStyle(
                                color: _onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Description
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          Text(
                            product.description!,
                            style: const TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 15,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Specs bento grid
                        _SpecsGrid(
                          categoryName: product.category.name,
                          stock: product.stock,
                          outOfStock: outOfStock,
                        ),
                        const SizedBox(height: 28),

                        // Trust signal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.local_shipping_outlined,
                              color: _onSurfaceVariant,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Complimentary botanical packaging & global shipping.',
                              style: TextStyle(
                                color: _onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // Bottom action bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomBar(
                  outOfStock: outOfStock,
                  quantity: _quantity,
                  maxStock: product.stock,
                  adding: _addingToCart,
                  onDecrement: () => setState(() => _quantity--),
                  onIncrement: () => setState(() => _quantity++),
                  onAddToCart: () => _addToCart(product.id, product.stock),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
  }
}

class _HeroImageCard extends StatelessWidget {
  final String imageUrl;
  const _HeroImageCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD7A417).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: const Color(0xFFF4F4EF)),
            errorWidget: (_, _, _) => Container(
              color: const Color(0xFFF4F4EF),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailGallery extends StatelessWidget {
  final String imageUrl;
  const _ThumbnailGallery({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: const Color(0xFFF4F4EF)),
                errorWidget: (_, _, _) =>
                    Container(color: const Color(0xFFF4F4EF)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4EF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF835425),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ethically Sourced &\nHand Selected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4F4634),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  final String categoryName;
  final int stock;
  final bool outOfStock;

  const _SpecsGrid({
    required this.categoryName,
    required this.stock,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SpecTile(
                label: 'Category',
                value: categoryName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SpecTile(
                label: 'Availability',
                value: outOfStock ? 'Out of Stock' : '$stock in stock',
                valueColor: outOfStock
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SpecTile(
          label: 'Delivery',
          value: 'Secure packaging · Ships within 3–5 business days',
          trailing: const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFFD7A417),
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _SpecTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD3C5AE).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF835425),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? const Color(0xFF1A1C19),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating.floor()
                ? Icons.star_rounded
                : (i - rating < 1 && i > rating.floor())
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: const Color(0xFF835425),
            size: 18,
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool outOfStock;
  final int quantity;
  final int maxStock;
  final bool adding;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.outOfStock,
    required this.quantity,
    required this.maxStock,
    required this.adding,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF8),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD3C5AE).withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF785A00).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!outOfStock) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: quantity > 1 ? onDecrement : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1C19),
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: quantity < maxStock ? onIncrement : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: outOfStock || adding ? null : onAddToCart,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: outOfStock
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFD7A417), Color(0xFFB3860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: outOfStock ? const Color(0xFFE0E0E0) : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: outOfStock
                      ? null
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFFD7A417).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: adding
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            outOfStock
                                ? 'OUT OF STOCK'
                                : 'ACQUIRE FOR SANCTUARY',
                            style: TextStyle(
                              color: outOfStock
                                  ? const Color(0xFF9E9E9E)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (!outOfStock) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.east,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? const Color(0xFFBDBDBD)
              : const Color(0xFF785A00),
        ),
      ),
    );
  }
}
