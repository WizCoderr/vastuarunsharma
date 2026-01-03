import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks app lifecycle state (foreground/background)
class AppLifecycleService with WidgetsBindingObserver {
  final _lifecycleController = StreamController<AppLifecycleState>.broadcast();

  AppLifecycleState _currentState = AppLifecycleState.resumed;
  DateTime? _lastBackgroundTime;

  AppLifecycleState get currentState => _currentState;
  DateTime? get lastBackgroundTime => _lastBackgroundTime;
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  Stream<AppLifecycleState> get lifecycleStream => _lifecycleController.stream;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastBackgroundTime = DateTime.now();
    }

    _lifecycleController.add(state);
  }

  /// Duration since app went to background (null if never backgrounded)
  Duration? get timeSinceBackground {
    if (_lastBackgroundTime == null) return null;
    return DateTime.now().difference(_lastBackgroundTime!);
  }
}

/// Singleton provider for lifecycle service
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for lifecycle state changes
final appLifecycleStateProvider = StreamProvider<AppLifecycleState>((ref) {
  final service = ref.watch(appLifecycleServiceProvider);
  return service.lifecycleStream;
});

/// Simple boolean provider for foreground state
final isAppInForegroundProvider = Provider<bool>((ref) {
  final lifecycleState = ref.watch(appLifecycleStateProvider);
  return lifecycleState.maybeWhen(
    data: (state) => state == AppLifecycleState.resumed,
    orElse: () => true, // Assume foreground initially
  );
});
