import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/data/models/remidies/category.dart';
import 'package:vastuarunsharma/domain/providers/remidies/cart_providers.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/cart_screen.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/remidies_products_screen.dart';

class RemidiesScreen extends ConsumerWidget {
  const RemidiesScreen({super.key});

  static const Color _primary = Color(0xFF984624);
  static const Color _onBackground = Color(0xFF1A1C1C);
  static const Color _onSurfaceVariant = Color(0xFF55433C);
  static const Color _background = Color(0xFFF9F9F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text(
          'Remidies comming soon...',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      )
    );
  }
  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _buildAppBar(context, cartItemCount),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) =>
                  _buildContent(context, ref, categories),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Error loading categories'),
              ),
            ),
          ),
        ],
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
          const Text(
            'Vastu Arun Sharma',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1917),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                  top: -4,
                  right: -6,
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorialHeader(),
          const SizedBox(height: 32),
          _buildAllProductsCard(context, ref),
          const SizedBox(height: 24),
          _buildCategoryGrid(context, ref, categories),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PURIFICATION & HARMONY',
          style: TextStyle(
            color: _primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
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
        const SizedBox(height: 16),
        const Text(
          'Curated metaphysical tools designed to align your physical space with universal energies. Browse our specialized collections.',
          style: TextStyle(color: _onSurfaceVariant, fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAllProductsCard(BuildContext context, WidgetRef ref) {
    return _CategoryCard(
      title: 'All Products',
      subtitle: 'Explore the complete sanctuary collection',
      imageUrl:
          'https://vastu-prod-data.s3.ap-south-1.amazonaws.com/vastu-courses/images/All%20Products.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAX47CH4GXOTUDVWMT%2F20260420%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20260420T235954Z&X-Amz-Expires=300&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGAaCmFwLXNvdXRoLTEiSDBGAiEAyE46GVEGX1HN839MhyJ4YBaGI2uVcW%2FsHQndKrzjcugCIQCRBbG%2BqFCLGSvMDgBRfy0X7LV78DwbMlTUDyoCuatpAirWAggpEAAaDDU0MzI1MDk2NDkxMCIMaCqLlxw%2FtTMQrRWjKrMCxHdbhPrbAIFrugeMQzMgMDUz7wCaeQqcFPPtiBXj9GTOFU84l81qW4YHjjXlD%2Ff4ZrVGRzhfRCu8g0ijAveHkLvDzXSzZZZF25wRcCejHEtKa4QjYZzTFLFHFXkYgfuvelwBHcKlqzXUY0r%2BtXvptRcSa0B3AUTwuCl9ciY%2FHzC32zMgXAM8%2FB330HKAmwAms2fFKYTk5oygQwkEPZwwRiooB3zQpbleoE6f7WPglp41n3ms1C7Sq658D%2BGYkmjXRJrNicVtATPOEzqzMzbKg69iZGJ6Y71c7f23m2eQlPs1wRxRMfYAPbX7WP%2Fb8zU5dvRximDDa4KFyysVzTR3ii0CwhMmqJKNsj2ulRlu1W%2FLsaKbDaWOkhprc7ET6yMJtrx8%2FvNLRnyMK1PnSClS9TY7yjD2%2BJrPBjqsAgaylVXf84hup0kTCUv6vimu8a5CO3t8ZeAJJt%2BTwQrkYXUb0FN%2F7g29mlzrqvXQroGpHNPSmWjEHmzu4aDJgscNcytZ1S0cA4eBg66xYDXFgm1iRx16fO9xiYRMmqLD1fy136s17aIlIRWl%2BQZVcwpPe0rKK%2FMsSPKw5tSEOYbHUiTs3Z%2B7KtKRVxC%2BTWbRLm4k3Fg8dRrte46w6%2Fc3ntIUGFFg4K2NQERW%2FZSluhSvgbmdu1qJ0GCdZHpzTo7nDw6zHF%2B1Hq%2F9TpiqQ7lCUKf7a204gNjQKau8KJ%2BX0Z%2FcxpEgmcicqJHExML3Vx9pRk2VmeCxvHuj6SZKvn6L2m6cypcROjbvkclEoI6d6MEnfhVZQH%2BRXI5jYiaEcloGbIeWbztQgSMLa3oXSA%3D%3D&X-Amz-Signature=95712aafba13fc5db22f1ab42a5747fdc6693dd6188676d755b0f22e2d4b6387&X-Amz-SignedHeaders=host&response-content-disposition=inline',
      height: 220,
      titleSize: 28,
      onTap: () {
        ref.read(selectedCategoryIdProvider.notifier).state = null;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RemidiesProductsScreen(
              title: 'All Products',
              categoryId: null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final category in categories) ...[
          _CategoryCard(
            title: category.name,
            subtitle: category.description ?? 'Explore ${category.name}',
            imageUrl: category.image ?? '',
            height: 200,
            titleSize: 24,
            onTap: () {
              ref.read(selectedCategoryIdProvider.notifier).state = category.id;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RemidiesProductsScreen(
                    title: category.name,
                    categoryId: category.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final double height;
  final double titleSize;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.height,
    required this.titleSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFFF3F3F3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: const Color(0xFFE2E2E2)),
                  errorWidget: (_, _, _) =>
                      Container(color: const Color(0xFFE2E2E2)),
                )
              else
                Container(color: const Color(0xFFE2E2E2)),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xB3000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
