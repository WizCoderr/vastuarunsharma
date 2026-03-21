import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/widgets/remidies_app_bar.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/widgets/remidies_category_filters.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/widgets/remidies_hero_banner.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/widgets/remidies_product_grid.dart';
import 'package:vastuarunsharma/presentation/screens/remidies/widgets/remidies_search_bar.dart';

class RemidiesScreen extends ConsumerWidget {
  const RemidiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text("Remidies Commming soon....."),
      ),
    );
  }
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RemidiesAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const RemidiesSearchBar(),
            const RemidiesCategoryFilters(),
            const RemidiesHeroBanner(),
            const SizedBox(height: 16),
            const RemidiesProductGrid(),
          ],
        ),
      ),
    );
  }
}
