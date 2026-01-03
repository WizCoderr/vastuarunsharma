import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_lifecycle_service.dart';
import '../../core/services/data_freshness_manager.dart';
import 'course_provider.dart';
import 'auth_provider.dart';

/// Handles automatic refresh on app resume
class RefreshOrchestrator {
  final Ref _ref;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  RefreshOrchestrator(this._ref) {
    _setupLifecycleListener();
  }

  void _setupLifecycleListener() {
    final service = _ref.read(appLifecycleServiceProvider);
    _lifecycleSubscription = service.lifecycleStream.listen((state) {
      if (state == AppLifecycleState.resumed) {
        _handleAppResume();
      }
    });
  }

  void _handleAppResume() {
    final service = _ref.read(appLifecycleServiceProvider);
    final freshnessManager = _ref.read(freshnessManagerProvider.notifier);
    final timeSinceBackground = service.timeSinceBackground;

    // Only refresh if user is logged in
    final authState = _ref.read(authStateProvider);
    if (authState.value == null) return;

    // Check and refresh stale data
    if (freshnessManager.needsRefreshAfterBackground(
      ProviderKeys.allCourses,
      timeSinceBackground,
    )) {
      _ref.invalidate(allCoursesProvider);
      freshnessManager.invalidate(ProviderKeys.allCourses);
    }

    if (freshnessManager.needsRefreshAfterBackground(
      ProviderKeys.enrolledCourses,
      timeSinceBackground,
    )) {
      _ref.invalidate(enrolledCoursesProvider);
      freshnessManager.invalidate(ProviderKeys.enrolledCourses);
    }
  }

  void dispose() {
    _lifecycleSubscription?.cancel();
  }
}

final refreshOrchestratorProvider = Provider<RefreshOrchestrator>((ref) {
  final orchestrator = RefreshOrchestrator(ref);
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

/// Extension methods for easy provider invalidation after user actions
extension RefreshExtensions on WidgetRef {
  /// Call after successful enrollment/payment
  void refreshAfterEnrollment() {
    // Invalidate all course-related providers
    invalidate(enrolledCoursesProvider);
    invalidate(allCoursesProvider);

    // Clear freshness records
    read(freshnessManagerProvider.notifier).invalidate(
      ProviderKeys.enrolledCourses,
    );
    read(freshnessManagerProvider.notifier).invalidate(ProviderKeys.allCourses);
  }

  /// Call to refresh a specific course
  void refreshCourseDetails(String courseId) {
    invalidate(courseDetailsProvider(courseId));
    read(freshnessManagerProvider.notifier).invalidate(
      ProviderKeys.courseDetailsKey(courseId),
    );
  }
}
