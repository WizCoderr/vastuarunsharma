import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for Picture-in-Picture mode
class PipState {
  final bool isInPipMode;
  final bool isPipAvailable;

  PipState({
    this.isInPipMode = false,
    this.isPipAvailable = false,
  });

  PipState copyWith({
    bool? isInPipMode,
    bool? isPipAvailable,
  }) {
    return PipState(
      isInPipMode: isInPipMode ?? this.isInPipMode,
      isPipAvailable: isPipAvailable ?? this.isPipAvailable,
    );
  }
}

/// Notifier for PiP state management
class PipNotifier extends Notifier<PipState> {
  static const MethodChannel _channel = MethodChannel('vastu_mobile/pip');

  @override
  PipState build() {
    _checkPipAvailability();
    _setupPipListener();
    return PipState();
  }

  Future<void> _checkPipAvailability() async {
    try {
      final isAvailable = await _channel.invokeMethod<bool>('isPipAvailable');
      state = state.copyWith(isPipAvailable: isAvailable ?? false);
    } catch (e) {
      // PiP not available on this platform/device
      state = state.copyWith(isPipAvailable: false);
    }
  }

  void _setupPipListener() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipModeChanged':
          final isInPip = call.arguments as bool;
          state = state.copyWith(isInPipMode: isInPip);
          break;
      }
    });
  }

  /// Enter Picture-in-Picture mode
  Future<bool> enterPipMode({
    int? width,
    int? height,
  }) async {
    if (!state.isPipAvailable) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('enterPipMode', {
        'width': width ?? 16,
        'height': height ?? 9,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Exit Picture-in-Picture mode (if possible)
  Future<void> exitPipMode() async {
    try {
      await _channel.invokeMethod('exitPipMode');
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Provider for PiP state
final pipProvider = NotifierProvider<PipNotifier, PipState>(() {
  return PipNotifier();
});

/// Simple provider to check if device is in PiP mode
final isInPipModeProvider = Provider<bool>((ref) {
  return ref.watch(pipProvider).isInPipMode;
});

/// Provider to check if PiP is available on this device
final isPipAvailableProvider = Provider<bool>((ref) {
  return ref.watch(pipProvider).isPipAvailable;
});
