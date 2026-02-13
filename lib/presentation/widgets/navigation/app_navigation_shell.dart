import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/route_constants.dart';

class AppNavigationShell extends StatelessWidget {
  final Widget child;

  const AppNavigationShell({
    super.key,
    required this.child,
  });

  int _getIndexFromLocation(String location) {
    if (location.startsWith(RouteConstants.compass)) {
      return 1;
    } else if (location.startsWith('/courses') || location.startsWith('/my-courses')) {
      return 2;
    } else if (location.startsWith('/profile')) {
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
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            backgroundColor: Colors.white,
            elevation: 0,
            height: 65,
            indicatorColor: AppColors.primary.withOpacity(0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: currentIndex == 0 ? AppColors.primary : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.home,
                  color: AppColors.primary,
                ),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.explore_outlined,
                  color: currentIndex == 1 ? AppColors.primary : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.explore,
                  color: AppColors.primary,
                ),
                label: 'Compass',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.school_outlined,
                  color: currentIndex == 2 ? AppColors.primary : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.school,
                  color: AppColors.primary,
                ),
                label: 'Courses',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: currentIndex == 3 ? AppColors.primary : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
