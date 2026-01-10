import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/refresh_provider.dart';
import 'core/services/notification_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

class VastuApp extends ConsumerStatefulWidget {
  const VastuApp({super.key});

  @override
  ConsumerState<VastuApp> createState() => _VastuAppState();
}

class _VastuAppState extends ConsumerState<VastuApp> {
  bool _notificationInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the refresh orchestrator (starts lifecycle listening)
    ref.read(refreshOrchestratorProvider);
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter goRouter = ref.watch(goRouterProvider);

    if (!_notificationInitialized) {
      _notificationInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationServiceProvider).initialize(goRouter);
      });
    }

    // Remove splash screen when UI is ready
    FlutterNativeSplash.remove();

    return MaterialApp.router(
      title: 'Vastu Arun Sharma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
