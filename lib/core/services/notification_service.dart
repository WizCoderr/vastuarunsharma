import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../constants/route_constants.dart';
import '../../presentation/providers/live_class_provider.dart';
import '../../domain/entities/live_class.dart';

// Provider to access the service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize(GoRouter router) async {
    // Initialize Timezone
    tz.initializeTimeZones();

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher_circle');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null) {
          router.push(RouteConstants.courseDetailsPath(response.payload!));
        }
      },
    );

    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      // Sync token immediately after permission is granted to ensure backend has it
      await syncToken();

      // Also request permissions for local notifications specifically on Android 13+ if needed,
      // though Firebase's request usually covers the OS permission.
      // We can explicitly request for local notifications to be safe / for platform specific controls
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else {
      debugPrint('User declined or has not accepted permission');
      // We don't return here, we still want to set up listeners in case
      // permissions are granted later or for silence messages if that's a thing
    }

    // 2. Handle background message (when app is opened from terminated state)
    // setupInteractedMessage(router); // Logic moved to main or handled via onMessageOpenedApp

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground Message: ${message.notification?.title}");

      if (message.notification != null &&
          router.routerDelegate.navigatorKey.currentContext != null) {
        final context = router.routerDelegate.navigatorKey.currentContext!;
        // Ensure context is still valid if needed, though here we just grabbed it.
        // For strict lint compliance we can't easily check 'mounted' on a context derived this way
        // without a StatefulWidget, but we can wrap it.
        // Actually, just ignoring it is common for global keys, but let's try strict.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.notification!.title ?? 'New Notification',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (message.notification!.body != null)
                  Text(message.notification!.body!),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => _handleMessage(message, router),
            ),
          ),
        );
      }
    });

    // 4. Background/Terminated Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, router);
    });

    // 5. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      syncToken();
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, router);
    }
  }

  Future<void> scheduleClassNotifications(List<LiveClass> classes) async {
    // Cancel all previously scheduled to avoid duplicates/stale ones
    // Note: This might cancel other notifications if we had them.
    // Ideally we track IDs, but cancelling all is safer for "today's list updated"
    await _localNotifications.cancelAll();

    for (var liveClass in classes) {
      final scheduledTime = liveClass.scheduledAt; // UTC
      final now = DateTime.now().toUtc();

      // Calculate start time notification
      if (scheduledTime.isAfter(now)) {
        await _scheduleNotification(
          id: liveClass.id.hashCode,
          title: "Live Class Starting Now!",
          body: "${liveClass.title} is starting. Join now!",
          scheduledDate: scheduledTime,
          payload: liveClass.courseId,
        );
      }

      // Calculate 5 min reminder
      final reminderTime = scheduledTime.subtract(const Duration(minutes: 5));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          id: liveClass.id.hashCode + 1, // Unique ID
          title: "Class Starting Soon",
          body: "${liveClass.title} starts in 5 minutes.",
          scheduledDate: reminderTime,
          payload: liveClass.courseId,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'live_class_channel',
            'Live Classes',
            channelDescription: 'Notifications for live class reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // uiLocalNotificationDateInterpretation:
        //    UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint("Scheduled notification '$title' for $scheduledDate");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
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
