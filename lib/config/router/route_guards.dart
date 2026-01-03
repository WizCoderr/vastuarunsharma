import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';

// Helper to check auth state
bool isUserLoggedIn(AsyncValue<dynamic> authState) {
  return authState.hasValue && authState.value != null;
}

// 1. Auth Guard: Ensures user is logged in
FutureOr<String?> authGuard(
  BuildContext context,
  GoRouterState state,
  AsyncValue<dynamic> authState,
) {
  final isLoggedIn = isUserLoggedIn(authState);

  if (!isLoggedIn) {
    // User is guest, trying to access protected route
    // Redirect to Login with return URL
    final currentPath = state.uri.toString();
    return '${RouteConstants.login}?returnUrl=$currentPath';
  }

  return null; // Access granted
}

// 2. Landing Guard: Ensures authenticated users DO NOT see Landing
FutureOr<String?> landingGuard(
  BuildContext context,
  GoRouterState state,
  AsyncValue<dynamic> authState,
) {
  final isLoggedIn = isUserLoggedIn(authState);

  if (isLoggedIn) {
    // Authenticated user trying to access Landing -> Redirect to Dashboard
    return RouteConstants.dashboard;
  }

  return null; // Guest user -> Access granted
}

// 3. Enrollment Guard: Ensures user is enrolled before accessing video
FutureOr<String?> enrollmentGuard(
  BuildContext context,
  GoRouterState state,
  AsyncValue<dynamic> authState,
) {
  final isLoggedIn = isUserLoggedIn(authState);

  if (!isLoggedIn) {
    final currentPath = state.uri.toString();
    return '${RouteConstants.login}?returnUrl=$currentPath';
  }

  // Allow if coming from enrollment screen (user just enrolled)
  final previousRoute = state.uri.toString();
  if (previousRoute.contains('/enrollment/')) {
    return null; // Access granted
  }

  // Check enrollment for direct access
  final user = authState.value;
  final courseId = state.pathParameters['courseId'];

  if (courseId != null && user != null) {
    if (!user.isEnrolled(courseId)) {
      // Not enrolled -> Redirect to Enrollment page
      return RouteConstants.enrollmentPath(courseId);
    }
  }

  return null; // Access granted
}
