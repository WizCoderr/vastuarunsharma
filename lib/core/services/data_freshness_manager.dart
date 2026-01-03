import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration for data staleness thresholds
class FreshnessConfig {
  /// How long before data is considered stale (default: 2 minutes)
  final Duration staleThreshold;

  /// Minimum time away before triggering refresh on resume (default: 30 seconds)
  final Duration backgroundThreshold;

  const FreshnessConfig({
    this.staleThreshold = const Duration(minutes: 2),
    this.backgroundThreshold = const Duration(seconds: 30),
  });
}

/// Provider keys for tracking different data types
class ProviderKeys {
  static const allCourses = 'allCourses';
  static const enrolledCourses = 'enrolledCourses';
  static const courseDetails = 'courseDetails';

  static String courseDetailsKey(String courseId) => 'courseDetails:$courseId';
}

/// Tracks when data was last fetched
class DataFreshnessManager extends Notifier<Map<String, DateTime>> {
  final FreshnessConfig config;

  DataFreshnessManager({this.config = const FreshnessConfig()});

  @override
  Map<String, DateTime> build() => {};

  /// Record when a provider's data was fetched
  void recordFetch(String providerKey) {
    state = {...state, providerKey: DateTime.now()};
  }

  /// Check if data is stale
  bool isStale(String providerKey) {
    final lastFetch = state[providerKey];
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > config.staleThreshold;
  }

  /// Check if refresh is needed after returning from background
  bool needsRefreshAfterBackground(
    String providerKey,
    Duration? timeSinceBackground,
  ) {
    if (timeSinceBackground == null) return false;
    if (timeSinceBackground < config.backgroundThreshold) return false;
    return isStale(providerKey);
  }

  /// Get all stale provider keys
  List<String> getStaleProviders() {
    return state.entries
        .where(
          (e) => DateTime.now().difference(e.value) > config.staleThreshold,
        )
        .map((e) => e.key)
        .toList();
  }

  /// Clear freshness record for a provider (forces refetch)
  void invalidate(String providerKey) {
    state = Map.from(state)..remove(providerKey);
  }

  /// Clear all freshness records
  void invalidateAll() {
    state = {};
  }
}

final freshnessManagerProvider =
    NotifierProvider<DataFreshnessManager, Map<String, DateTime>>(() {
  return DataFreshnessManager(
    config: const FreshnessConfig(
      staleThreshold: Duration(minutes: 2),
      backgroundThreshold: Duration(seconds: 30),
    ),
  );
});
