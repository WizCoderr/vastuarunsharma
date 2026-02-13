import 'package:flutter/material.dart';
import '../DashboardColors.dart';

class InstructorCard extends StatelessWidget {
  const InstructorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.accentGoldLight,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/instructor.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arun Sharma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MASTER EDUCATOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.accentGold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Arun Sharma is a professional Vastu Consultant and Vastu Educator with over five years of focused experience in Vastu Shastra and energy-based space planning. Known for his structured methodology and logical approach, he has built a reputation for delivering practical, result-oriented Vastu solutions that align traditional principles with modern living and business environments',
            style: TextStyle(
              fontSize: 14,
              color: DashboardColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Read More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.accentGold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: DashboardColors.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
