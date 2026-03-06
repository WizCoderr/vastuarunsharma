import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

class RemidiesCategoryFilters extends ConsumerWidget {
  const RemidiesCategoryFilters({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return SizedBox(
      height: 48,
      child: categoriesAsync.when(
        data: (categories) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _CategoryFilterChip(
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).state = null;
                },
              ),
              ...categories.map(
                (category) => _CategoryFilterChip(
                  label: category.name,
                  isSelected: selectedCategoryId == category.id,
                  onTap: () {
                    ref.read(selectedCategoryIdProvider.notifier).state =
                        category.id;
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _CategoryFilterChip(
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).state = null;
                },
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  'Categories will be added soon',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
