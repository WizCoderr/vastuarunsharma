import 'package:flutter/material.dart';

class FeaturedWisdomCard extends StatelessWidget {
  final String imagePath;

  const FeaturedWisdomCard({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(
            0xFFE8EBF2,
          ), // Light grey/blueish background from design
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Image.asset(imagePath, width: 120, height: 120, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
