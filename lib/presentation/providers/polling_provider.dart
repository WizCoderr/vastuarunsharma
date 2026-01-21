import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/services/app_lifecycle_service.dart';
import '../../core/services/data_freshness_manager.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/course.dart';
import 'course_provider.dart';

/// Configuration for polling
class PollingConfig {
  final Duration interval;

  const PollingConfig({this.interval = const Duration(seconds: 10)});
}

/// Tracks if My Courses screen is visible
final isMyCoursesVisibleProvider = StateProvider<bool>((ref) => false);

/// Manages polling for enrolled courses
/// Only polls when:
/// 1. App is in foreground
/// 2. My Courses screen is visible (tracked via isMyCoursesVisibleProvider)
/// 3. Only updates if data has actually changed
class EnrolledCoursesPollingManager extends Notifier<bool> {
  final PollingConfig config;
  Timer? _pollTimer;

  EnrolledCoursesPollingManager({this.config = const PollingConfig()});

  @override
  bool build() => false;

  /// Start polling (call when My Courses screen becomes visible)
  void startPolling() {
    if (_pollTimer != null) return; // Already polling

    state = true;
    _pollTimer = Timer.periodic(config.interval, (_) {
      _pollIfAllowed();
    });
  }

  /// Stop polling (call when My Courses screen is hidden)
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = false;
  }

  Future<void> _pollIfAllowed() async {
    // Check if app is in foreground
    final isInForeground = ref.read(isAppInForegroundProvider);
    if (!isInForeground) return;

    // Check if screen is still visible
    final isVisible = ref.read(isMyCoursesVisibleProvider);
    if (!isVisible) {
      stopPolling();
      return;
    }

    // Get current cached data
    final currentState = ref.read(enrolledCoursesProvider);
    final currentCourses = currentState.asData?.value;

    try {
      // Fetch fresh data directly from repository
      final repository = ref.read(courseRepositoryProvider);
      final result = await repository.getEnrolledCourses();

      result.fold(
        (failure) {
          // Don't update on error, keep existing data
          debugPrint('Polling failed: ${failure.message}');
          if (failure is AuthFailure) {
            debugPrint('Polling stopped due to auth failure');
            stopPolling();
          }
        },
        (newCourses) {
          // Compare with current data
          if (_hasDataChanged(currentCourses, newCourses)) {
            debugPrint('Polling: Data changed, refreshing UI');
            // Data changed, invalidate to update UI
            ref.invalidate(enrolledCoursesProvider);
            ref
                .read(freshnessManagerProvider.notifier)
                .recordFetch(ProviderKeys.enrolledCourses);
          } else {
            debugPrint('Polling: No changes detected');
            // Just update freshness timestamp without invalidating
            ref
                .read(freshnessManagerProvider.notifier)
                .recordFetch(ProviderKeys.enrolledCourses);
          }
        },
      );
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  /// Compare two course lists to detect changes
  bool _hasDataChanged(List<Course>? oldCourses, List<Course> newCourses) {
    // If no previous data, consider it changed
    if (oldCourses == null) return true;

    // Different count means changed
    if (oldCourses.length != newCourses.length) return true;

    // Compare course IDs (order matters for enrollment list)
    final oldIds = oldCourses.map((c) => c.id).toList();
    final newIds = newCourses.map((c) => c.id).toList();

    for (int i = 0; i < oldIds.length; i++) {
      if (oldIds[i] != newIds[i]) return true;
    }

    // Compare key properties that might change
    for (int i = 0; i < oldCourses.length; i++) {
      final oldCourse = oldCourses[i];
      final newCourse = newCourses[i];

      // Check if title, sections count, or lectures count changed
      if (oldCourse.title != newCourse.title ||
          oldCourse.sections.length != newCourse.sections.length ||
          oldCourse.enrolled != newCourse.enrolled) {
        return true;
      }

      // Check total lecture count
      final oldLectureCount = oldCourse.sections.fold<int>(
        0,
        (sum, s) => sum + s.lectures.length,
      );
      final newLectureCount = newCourse.sections.fold<int>(
        0,
        (sum, s) => sum + s.lectures.length,
      );
      if (oldLectureCount != newLectureCount) return true;
    }

    return false;
  }
}

/// Polling manager provider
final enrolledCoursesPollingProvider =
    NotifierProvider<EnrolledCoursesPollingManager, bool>(() {
      return EnrolledCoursesPollingManager();
    });
