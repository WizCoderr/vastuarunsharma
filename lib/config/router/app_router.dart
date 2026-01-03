import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/landing/landing_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/courses/courses_list_screen.dart';
import '../../presentation/screens/courses/course_details_screen.dart';
import '../../presentation/screens/courses/my_courses_screen.dart';
import '../../presentation/screens/enrollment/enrollment_screen.dart';
import '../../presentation/screens/video/video_player_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/pdf/pdf_viewer_screen.dart';
import '../../presentation/widgets/navigation/app_navigation_shell.dart';
import 'router_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  // Cache auth state to avoid calling ref.read during widget disposal
  bool isLoggedIn() {
    final authState = ref.read(authStateProvider);
    return authState.asData?.value != null;
  }

  return GoRouter(
    initialLocation: RouteConstants.landing,
    refreshListenable: notifier,
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
    redirect: (context, state) {
      final loggedIn = isLoggedIn();
      final isLoggingIn =
          state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register;

      // If not logged in and not heading to auth/landing/courses/public pages, redirect to landing
      if (!loggedIn &&
          !isLoggingIn &&
          state.matchedLocation != RouteConstants.landing &&
          state.matchedLocation != RouteConstants.courses &&
          state.matchedLocation != RouteConstants.dashboard &&
          state.matchedLocation != RouteConstants.profile &&
          !state.matchedLocation.startsWith('/course/')) {
        return RouteConstants.landing;
      }
      return null;
    },
    routes: [
      // Routes outside shell (no bottom nav)
      GoRoute(
        path: RouteConstants.landing,
        builder: (context, state) => const LandingScreen(),
        redirect: (context, state) {
          // If logged in, skip landing
          if (isLoggedIn()) {
            return RouteConstants.dashboard;
          }
          return null;
        },
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) {
          final returnUrl = state.uri.queryParameters['returnUrl'];
          return LoginScreen(returnUrl: returnUrl);
        },
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) {
          final returnUrl = state.uri.queryParameters['returnUrl'];
          return RegisterScreen(returnUrl: returnUrl);
        },
      ),
      GoRoute(
        path: '/course/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return CourseDetailsScreen(courseId: courseId);
        },
      ),
      GoRoute(
        name: RouteConstants.enrollment,
        path: '/enrollment/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return EnrollmentScreen(courseId: courseId);
        },
      ),
      GoRoute(
        name: RouteConstants.videoPlayer,
        path: '/video/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return VideoPlayerScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: RouteConstants.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/payment/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return CheckoutScreen(courseId: courseId);
        },
        redirect: (context, state) {
          if (!isLoggedIn()) {
            return '${RouteConstants.login}?returnUrl=${state.matchedLocation}';
          }
          return null;
        },
      ),

      // Shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppNavigationShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.courses,
            builder: (context, state) => const CoursesScreen(),
          ),
          GoRoute(
            path: RouteConstants.myCourses,
            builder: (context, state) => const MyCoursesScreen(),
            redirect: (context, state) {
              if (!isLoggedIn()) {
                return '${RouteConstants.login}?returnUrl=${state.matchedLocation}';
              }
              return null;
            },
          ),
          GoRoute(
            path: RouteConstants.profile,
            builder: (context, state) => const ProfileScreen(),
            // No redirect - show guest view with login prompt
          ),
        ],
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PdfViewerScreen(
            url: extra['url'] as String,
            title: extra['title'] as String,
          );
        },
      ),
    ],
  );
});
