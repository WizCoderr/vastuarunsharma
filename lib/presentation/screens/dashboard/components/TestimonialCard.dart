import 'package:flutter/material.dart';
import '../../../../domain/entities/testimonial.dart';
import '../DashboardColors.dart';
import '../../../widgets/glass_container.dart';

class TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const TestimonialCard({
    super.key,
    required this.testimonial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40, bottom: 20, left: 8, right: 8), // Top margin for image overlap
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Card Content
          GlassContainer(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), // Top padding for image space
            borderRadius: 24,
            opacity: 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  testimonial.authorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1), // Deep Blue color from screenshot
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < testimonial.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFC107), // Amber
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  '"${testimonial.text}"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: DashboardColors.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Profile Image (Popping out)
          Positioned(
            top: -40, // Half of 80 height
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(testimonial.profilePhotoUrl),
                onBackgroundImageError: (_, _) => const Icon(Icons.person),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
