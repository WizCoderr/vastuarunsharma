import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/route_constants.dart';
import '../../widgets/glass_container.dart';

class AppNavigationShell extends StatelessWidget {
  final Widget child;

  const AppNavigationShell({
    super.key,
    required this.child,
  });

  int _getIndexFromLocation(String location) {
    if (location.startsWith(RouteConstants.compass)) {
      return 1;
    } else if (location.startsWith(RouteConstants.courses) ||
        location.startsWith('/my-courses')) {
      return 2;
    } else if (location.startsWith(RouteConstants.profile)) {
      return 3;
    }
    return 0; // Dashboard
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteConstants.dashboard);
        break;
      case 1:
        context.go(RouteConstants.compass);
        break;
      case 2:
        context.go(RouteConstants.courses);
        break;
      case 3:
        context.go(RouteConstants.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndexFromLocation(location);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          context.go(RouteConstants.dashboard);
        }
      },
      child: Scaffold(
        extendBody: true, // Allow body to extend behind the navigation bar
        body: child,
        bottomNavigationBar: Platform.isIOS
            ? _buildIOSNavigation(context, currentIndex)
            : _buildAndroidNavigation(context, currentIndex),
      ),
    );
  }

  Widget _buildIOSNavigation(BuildContext context, int currentIndex) {
    return GlassContainer(
      margin: const EdgeInsets.all(20),
      borderRadius: 30,
      opacity: 0.8,
      blur: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
        child: GNav(
          rippleColor: Colors.grey[300]!,
          hoverColor: Colors.grey[100]!,
          gap: 8,
          activeColor: AppColors.primary,
          iconSize: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(milliseconds: 400),
          tabBackgroundColor: AppColors.primary.withOpacity(0.1),
          color: Colors.grey[600],
          tabs: const [
            GButton(
              icon: Icons.home_rounded,
              text: 'Home',
            ),
            GButton(
              icon: Icons.explore_rounded,
              text: 'Compass',
            ),
            GButton(
              icon: Icons.school_rounded,
              text: 'Courses',
            ),
            GButton(
              icon: Icons.person_rounded,
              text: 'Profile',
            ),
          ],
          selectedIndex: currentIndex,
          onTabChange: (index) => _onDestinationSelected(context, index),
        ),
      ),
    );
  }

  Widget _buildAndroidNavigation(BuildContext context, int currentIndex) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      backgroundColor: Colors.white,
      elevation: 2,
      height: 70, // Slightly taller for better touch targets
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
            color: currentIndex == 0 ? AppColors.primary : Colors.grey[600],
          ),
          selectedIcon: const Icon(
            Icons.home_rounded,
            color: AppColors.primary,
          ),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.explore_outlined,
            color: currentIndex == 1 ? AppColors.primary : Colors.grey[600],
          ),
          selectedIcon: const Icon(
            Icons.explore_rounded,
            color: AppColors.primary,
          ),
          label: 'Compass',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.school_outlined,
            color: currentIndex == 2 ? AppColors.primary : Colors.grey[600],
          ),
          selectedIcon: const Icon(
            Icons.school_rounded,
            color: AppColors.primary,
          ),
          label: 'Courses',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline,
            color: currentIndex == 3 ? AppColors.primary : Colors.grey[600],
          ),
          selectedIcon: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
