import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/cart_screen.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/product_detail_screen.dart';

class RemidiesProductsScreen extends ConsumerStatefulWidget {
  final String title;
  final String? categoryId;

  const RemidiesProductsScreen({
    super.key,
    required this.title,
    this.categoryId,
  });

  @override
  ConsumerState<RemidiesProductsScreen> createState() =>
      _RemidiesProductsScreenState();
}

class _RemidiesProductsScreenState
    extends ConsumerState<RemidiesProductsScreen> {
  // Scholar's Gilt golden palette
  static const Color _primary = Color(0xFF785A00);
  static const Color _primaryContainer = Color(0xFFD7A417);
  static const Color _background = Color(0xFFFAFAF5);
  static const Color _surfaceContainerHigh = Color(0xFFE8E8E4);
  static const Color _surfaceContainerHighest = Color(0xFFE2E3DE);
  static const Color _onSurface = Color(0xFF1A1C19);
  static const Color _onSurfaceVariant = Color(0xFF4F4634);
  static const Color _outlineVariant = Color(0xFFD3C5AE);

  final TextEditingController _searchController = TextEditingController();
  int _selectedChip = 0;

  List<String> get _chips =>
      [widget.title, 'Popular', 'New Arrivals', 'Talismans'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider((
        page: 1,
        limit: 50,
        categoryId: widget.categoryId,
      )),
    );
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.filter_list_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(cartItemCount),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryContainer),
                ),
                error: (error, _) => _buildError(error.toString()),
                data: (result) {
                  var products = result['products'] as List<Product>;
                  final searchQuery = ref.watch(searchQueryProvider);
                  if (searchQuery.isNotEmpty) {
                    final q = searchQuery.toLowerCase();
                    products = products
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(q) ||
                              (p.description?.toLowerCase().contains(q) ??
                                  false),
                        )
                        .toList();
                  }
                  return _buildContent(products);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(int cartItemCount) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF8),
        border: Border(
          bottom: BorderSide(
            color: _outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: _primary),
          ),
          Expanded(
            child: const Text(
              'All Products',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: _primary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: _primary,
                ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 17, minHeight: 17),
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartItemCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Failed to load products.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(productsProvider),
              child: const Text(
                'Retry',
                style: TextStyle(color: _primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Product> products) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearch()),
        SliverToBoxAdapter(child: _buildChips()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products in ${widget.title}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(product: products[index]),
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          style: const TextStyle(color: _onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search for healing bracelets...',
            hintStyle: TextStyle(
              color: _onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: _onSurfaceVariant,
              size: 20,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final selected = i == _selectedChip;
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? _primaryContainer
                    : _surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _primaryContainer.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _chips[i].toUpperCase(),
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF523C00)
                      : _onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  static const Color _primary = Color(0xFF785A00);
  static const Color _onSurface = Color(0xFF1A1C19);
  static const Color _surfaceContainerLow = Color(0xFFF4F4EF);

  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF785A00).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: _surfaceContainerLow),
                  CachedNetworkImage(
                    imageUrl: product.image ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: _surfaceContainerLow),
                    errorWidget: (_, _, _) => Container(
                      color: _surfaceContainerLow,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isFavorited = !_isFavorited),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Stars(rating: product.rating, count: product.reviewCount),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${_formatPrice(product.price)}',
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _AddButton(
                          disabled: product.isOutOfStock,
                          onTap: () {
                            ref.read(addToCartProvider.call((product.id, 1)));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: _primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    }
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    final thousands = str.substring(0, str.length - 3);
    final rest = str.substring(str.length - 3);
    return '$thousands,$rest';
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  final int count;
  const _Stars({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: const Color(0xFFD7A417),
            size: 13,
          ),
        const SizedBox(width: 3),
        Text(
          '($count)',
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool disabled;
  final VoidCallback onTap;

  const _AddButton({required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade300 : const Color(0xFF785A00),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          color: disabled ? Colors.grey.shade600 : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
