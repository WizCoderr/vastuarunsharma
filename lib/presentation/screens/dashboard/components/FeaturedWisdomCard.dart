import 'package:flutter/material.dart';
import '../../../widgets/glass_container.dart';

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
      child: GlassContainer(
        width: double.infinity,
        borderRadius: 24,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8EBF2).withOpacity(0.8),
            const Color(0xFFE8EBF2).withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        child: Center(
          child: Image.asset(imagePath, width: 120, height: 120, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
