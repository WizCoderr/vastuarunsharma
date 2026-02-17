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
                childAspectRatio: 0.8,
                children: [
                  _buildCompassCard(
                    context,
                    title: "Vastu Compass",
                    icon: "assets/images/compass.png",
                    route: RouteConstants.compassNormal,
                  ),
                  _buildCompassCard(
                    context,
                    title: "16 Zone Vastu Compass",
                    icon: "assets/images/16zonecompass.png",
                    route: RouteConstants.compassSixteen,
                  ),
                  _buildCompassCard(
                    context,
                    title: "42 Devta Vastu Compass",
                    icon: "assets/images/42Devta.png",
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
    required String icon,
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth.isInfinite ||
                      constraints.maxHeight.isInfinite) {
                    return const SizedBox();
                  }
                  final size = constraints.biggest.shortestSide;
                  return Center(
                    child: Container(
                      width: size,
                      height: size,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DashboardColors.accentGreenLight
                      ),
                      child: Image.asset(
                        icon,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
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
