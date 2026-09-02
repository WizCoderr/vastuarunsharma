import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vastuarunsharma/presentation/screens/compass/screens/SixteenZoneCompass.dart';
import 'package:vastuarunsharma/presentation/screens/compass/screens/ThirtytwoZoneCompass.dart';

import '../../core/constants/route_constants.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/compass/compas_home.dart';
import '../../presentation/screens/compass/compass_result_screen.dart';
import '../../presentation/screens/compass/screens/compas_screen.dart';
import '../../presentation/screens/courses/course_details_screen.dart';
import '../../presentation/screens/courses/courses_list_screen.dart';
import '../../presentation/screens/courses/my_courses_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/enrollment/enrollment_screen.dart';
import '../../presentation/screens/landing/landing_screen.dart';
import '../../presentation/screens/payment/payment_progress_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/payment/remedies_payment_screen.dart';
import '../../presentation/screens/admin/remidies/admin_bulk_tiers_screen.dart';
import '../../presentation/screens/admin/remidies/admin_coupons_screen.dart';
import '../../presentation/screens/pdf/pdf_viewer_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/remidies/remidies_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/screens/video/video_player_screen.dart';
import '../../presentation/widgets/navigation/app_navigation_shell.dart';
import 'router_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  bool isLoggedIn() {
    final authState = ref.read(authStateProvider);
    final hasStoredToken = ref.read(authRepositoryProvider).hasToken;
    return authState.asData?.value != null || hasStoredToken;
  }

  bool isAdmin() {
    final authState = ref.read(authStateProvider);
    return authState.asData?.value?.role == 'admin';
  }

  return GoRouter(
    initialLocation: isLoggedIn()
        ? RouteConstants.dashboard
        : RouteConstants.landing,
    refreshListenable: notifier,
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) {
        return null;
      }

      final loggedIn =
          authState.asData?.value != null ||
          ref.read(authRepositoryProvider).hasToken;
      final isAuthRoute =
          state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register ||
          state.matchedLocation == RouteConstants.forgotPassword ||
          state.matchedLocation == RouteConstants.resetPassword;

      if (loggedIn &&
          (state.matchedLocation == RouteConstants.landing ||
              state.matchedLocation == RouteConstants.login ||
              state.matchedLocation == RouteConstants.register)) {
        return RouteConstants.dashboard;
      }

      if (!loggedIn &&
          !isAuthRoute &&
          state.matchedLocation != RouteConstants.landing &&
          state.matchedLocation != RouteConstants.courses &&
          state.matchedLocation != RouteConstants.dashboard &&
          !state.matchedLocation.startsWith(RouteConstants.compass) &&
          state.matchedLocation != RouteConstants.compassResult &&
          state.matchedLocation != RouteConstants.profile &&
          !state.matchedLocation.startsWith('/course/')) {
        return RouteConstants.landing;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.landing,
        builder: (context, state) => const LandingScreen(),
        redirect: (context, state) {
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
        path: RouteConstants.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteConstants.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final devOtp = state.uri.queryParameters['devOtp'];
          return ResetPasswordScreen(email: email, devOtp: devOtp);
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
          final lectureId = state.uri.queryParameters['lectureId'];
          final recordingId = state.uri.queryParameters['recordingId'];
          return VideoPlayerScreen(
            courseId: courseId,
            initialLectureId: lectureId,
            initialRecordingId: recordingId,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: RouteConstants.checkoutPath,
        builder: (context, state) {
          final courseId = state.extra as String;
          return CheckoutScreen(courseId: courseId);
        },
        redirect: (context, state) {
          if (!isLoggedIn()) {
            return '${RouteConstants.login}?returnUrl=${state.matchedLocation}';
          }
          return null;
        },
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
      GoRoute(
        path: RouteConstants.remediesPaymentPath,
        builder: (context, state) {
          final orderId = state.extra as String;
          return RemediesPaymentScreen(orderId: orderId);
        },
        redirect: (context, state) {
          if (!isLoggedIn()) {
            return '${RouteConstants.login}?returnUrl=${state.matchedLocation}';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/payment-progress/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return PaymentProgressScreen(courseId: courseId);
        },
        redirect: (context, state) {
          if (!isLoggedIn()) {
            return '${RouteConstants.login}?returnUrl=${state.matchedLocation}';
          }
          return null;
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppNavigationShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteConstants.compass,
            builder: (context, state) => const CompassHomeScreen(),
            routes: [
              GoRoute(
                name: 'compass-normal',
                path: 'normal',
                builder: (context, state) => const CompassScreen(),
              ),
              GoRoute(
                name: 'compass-16zone',
                path: '16-zone',
                builder: (context, state) => const SixteenZoneCompass(),
              ),
              GoRoute(
                name: 'compass-32zone',
                path: '32-zone',
                builder: (context, state) => const Thirtytwozonecompass(),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.remidies,
            builder: (context, state) => const RemidiesScreen(),
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
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.adminRemidiesCoupons,
        builder: (context, state) => const AdminCouponsScreen(),
        redirect: (context, state) {
          if (!isLoggedIn()) return RouteConstants.login;
          if (!isAdmin()) return RouteConstants.dashboard;
          return null;
        },
      ),
      GoRoute(
        path: RouteConstants.adminRemidiesBulkTiers,
        builder: (context, state) => const AdminBulkTiersScreen(),
        redirect: (context, state) {
          if (!isLoggedIn()) return RouteConstants.login;
          if (!isAdmin()) return RouteConstants.dashboard;
          return null;
        },
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
      GoRoute(
        path: RouteConstants.compassResult,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          final imagePath = extras?['imagePath'] as String? ?? '';
          return CompassResultScreen(imagePath: imagePath);
        },
      ),
    ],
  );
});
