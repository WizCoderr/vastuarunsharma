import 'package:flutter/material.dart';
import '../DashboardColors.dart';
import '../../../widgets/glass_container.dart';

class InstructorCard extends StatelessWidget {
  const InstructorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Arun Sharma',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Arun Sharma is a seasoned Vastu consultant with over 15 years of experience in the field. He has helped numerous clients create harmonious living and working spaces by applying the principles of Vastu Shastra. Arun's expertise lies in analyzing the energy flow of spaces and providing practical solutions to enhance well-being and prosperity.",
            style: const TextStyle(
              fontSize: 15,
              color: DashboardColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/DSC06354.JPG',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
