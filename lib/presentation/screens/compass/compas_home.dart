import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vastuarunsharma/presentation/screens/dashboard/DashboardColors.dart';
import '../../../core/constants/route_constants.dart';
import '../../widgets/glass_container.dart';

class CompassHomeScreen extends StatelessWidget {
  const CompassHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text(
          "Select Compasses Type",
          style: TextStyle(
            color: DashboardColors.accentGold, // Blue title as per mockup
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Card shape
                children: [
                  _buildCompassCard(
                    context,
                    title: "Normal Compass",
                    icon: Icons.explore, // Placeholder
                    route: RouteConstants.compassNormal,
                  ),
                  _buildCompassCard(
                    context,
                    title: "16 Zone Vastu Compass",
                    icon: Icons.grid_view, // Placeholder
                    route: RouteConstants.compassSixteen,
                  ),
                  _buildCompassCard(
                    context,
                    title: "42 Devta Vastu Compass",
                    icon: Icons.grid_on, // Placeholder
                    route: RouteConstants.compassThirtyTwo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          context.push(route);
        } else if (onTap != null) {
          onTap();
        }
      },
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.accentGold,
              ),
              child: Icon(icon, size: 48, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
