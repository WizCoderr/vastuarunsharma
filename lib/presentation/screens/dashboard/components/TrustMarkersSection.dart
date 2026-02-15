import 'package:flutter/material.dart';
import '../DashboardColors.dart';

class TrustMarkersSection extends StatelessWidget {
  const TrustMarkersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(
            icon: Icons.lock_outline_rounded,
            label: "Private &\nConfidential",
            iconColor: Colors.orange,
          ),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          _buildTrustItem(
            icon: Icons.verified_user_outlined,
            label: "Verified Vastu\nExperts",
            iconColor: Colors.orange,
          ),
          Container(height: 40, width: 1, color: Colors.grey[200]),
          _buildTrustItem(
            icon: Icons.credit_card_rounded,
            label: "Secure\nPayments",
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: iconColor),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DashboardColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
