import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/route_constants.dart';
import '../../presentation/providers/live_class_provider.dart';

// Provider to access the service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService(this._ref);

  Future<void> initialize(GoRouter router) async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Handle background message (when app is opened from terminated state)
    // setupInteractedMessage(router); // Logic moved to main or handled via onMessageOpenedApp

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       // Show local notification if needed, or just let the user see inside app if we had an in-app inbox.
       // For now, we rely on the system tray notification if in background, 
       // or we could show a snackbar if in foreground.
       debugPrint("Foreground Message: ${message.notification?.title}");
    });

    // 4. Background/Terminated Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, router);
    });
    
    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, router);
    }
  }

  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }
  
  // Sync token with backend
  Future<void> syncToken() async {
    try {
      final token = await getDeviceToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _ref.read(liveClassRepositoryProvider).registerDeviceToken(token);
      }
    } catch (e) {
      debugPrint("Failed to sync token: $e");
    }
  }

  Future<void> removeToken() async {
    try {
      await _ref.read(liveClassRepositoryProvider).unregisterDeviceToken();
         await _messaging.deleteToken(); // Optional: invalidates on FCM side too
    } catch (e) {
      debugPrint("Failed to remove token: $e");
    }
  }

  void _handleMessage(RemoteMessage message, GoRouter router) {
    if (message.data.isEmpty) return;

    final type = message.data['type'];
    // LIVE_CLASS, RECORDING_AVAILABLE

    if (type == 'LIVE_CLASS') {
      final meetingUrl = message.data['meetingUrl'];
      if (meetingUrl != null) {
        // Open URL externally
        launchUrl(Uri.parse(meetingUrl), mode: LaunchMode.externalApplication);
      }
    } else if (type == 'RECORDING_AVAILABLE') {
      final courseId = message.data['courseId'];
      if (courseId != null) {
        router.push(RouteConstants.courseDetailsPath(courseId));
        // Ideally we scroll to recordings or highlight it, but basic nav is fine.
      }
    }
  }
}
