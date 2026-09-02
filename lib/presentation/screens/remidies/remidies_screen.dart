import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/data/models/remidies/product.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/cart_screen.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/product_detail_screen.dart';

bool isRemidiesShopOpeningSoon() => true ;

class RemidiesScreen extends ConsumerStatefulWidget {
  const RemidiesScreen({super.key});

  @override
  ConsumerState<RemidiesScreen> createState() => _RemidiesScreenState();
}

class _RemidiesScreenState extends ConsumerState<RemidiesScreen> {
  static const Color _primary = Color(0xFF984624);
  static const Color _onBackground = Color(0xFF1A1C1C);
  static const Color _onSurfaceVariant = Color(0xFF55433C);
  static const Color _background = Color(0xFFF9F9F9);

  @override
  void initState() {
    super.initState();
    // Default: show all products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCategoryIdProvider.notifier).state = null;
    });
  }

  Future<void> _onRefresh() async {
    final categoryId = ref.read(selectedCategoryIdProvider);
    await Future.wait([
      ref.refresh(categoriesProvider.future),
      ref.refresh(
        productsProvider((page: 1, limit: 50, categoryId: categoryId)).future,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    if (isRemidiesShopOpeningSoon()) {
      return Scaffold(
        backgroundColor: _background,
        body: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: const Center(
            child: Text(
              'Shop opening soon...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _onBackground,
              ),
            ),
          ),
        ),
      );
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final productsAsync = ref.watch(
      productsProvider((page: 1, limit: 50, categoryId: selectedCategoryId)),
    );

    return Scaffold(
      backgroundColor: _background,
      body: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Column(
          children: [
            _buildAppBar(context, cartItemCount),
            Expanded(
              child: RefreshIndicator(
                color: _primary,
                onRefresh: _onRefresh,
                child: categoriesAsync.when(
                  data: (categories) => _buildContent(
                    categories: categories,
                    selectedCategoryId: selectedCategoryId,
                    productsAsync: productsAsync,
                  ),
                  loading: () => const CustomScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      ),
                    ],
                  ),
                  error: (e, st) => const CustomScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('Error loading categories'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int cartItemCount) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _background.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Vastu Arun Sharma',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1917),
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF78716C),
                ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
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

  Widget _buildContent({
    required List<Category> categories,
    required String? selectedCategoryId,
    required AsyncValue<Map<String, dynamic>> productsAsync,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildEditorialHeader(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 8),
            child: _buildCategoryPills(
              categories: categories,
              selectedCategoryId: selectedCategoryId,
            ),
          ),
        ),
        productsAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator(color: _primary)),
          ),
          error: (e, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Failed to load products',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          data: (result) {
            final products = result['products'] as List<Product>;
            if (products.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No products available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _HomeProductCard(product: products[index]),
                  childCount: products.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryPills({
    required List<Category> categories,
    required String? selectedCategoryId,
  }) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _CategoryPill(
            label: 'All Products',
            isSelected: selectedCategoryId == null,
            onTap: () {
              ref.read(selectedCategoryIdProvider.notifier).state = null;
            },
          ),
          for (final category in categories)
            _CategoryPill(
              label: category.name,
              isSelected: selectedCategoryId == category.id,
              onTap: () {
                ref.read(selectedCategoryIdProvider.notifier).state =
                    category.id;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PURIFICATION & HARMONY',
          style: TextStyle(
            color: _primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: _onBackground,
              height: 1.1,
              letterSpacing: -1.2,
            ),
            children: [
              TextSpan(text: 'Remedies for\n'),
              TextSpan(
                text: 'Balanced Living',
                style: TextStyle(color: _primary),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Curated metaphysical tools designed to align your physical space with universal energies. Browse our specialized collections.',
          style: TextStyle(color: _onSurfaceVariant, fontSize: 16, height: 1.5),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: isSelected ? const Color(0xFF984624) : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF984624)
                : const Color(0xFFE7E0DA),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF55433C),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeProductCard extends ConsumerWidget {
  final Product product;

  const _HomeProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: const Color(0xFFF3F3F3)),
                  if (product.image != null && product.image!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: product.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: Color(0xFFF3F3F3)),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF3F3F3),
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  if (product.isOutOfStock)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _OutOfStockBadge(),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1A1C1C),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${_formatPrice(product.price)}',
                          style: const TextStyle(
                            color: Color(0xFF984624),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: product.isOutOfStock
                              ? null
                              : () async {
                                  try {
                                    await ref.read(
                                      addToCartProvider.call((
                                        product.id,
                                        1,
                                      )).future,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Added to cart'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: Icon(
                            Icons.add_shopping_cart_outlined,
                            color: product.isOutOfStock
                                ? Colors.grey
                                : const Color(0xFF984624),
                            size: 20,
                          ),
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

  static String _formatPrice(double price) {
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Out of Stock',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
