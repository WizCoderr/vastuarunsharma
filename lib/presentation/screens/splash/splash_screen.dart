import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is valid and providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          context.go(RouteConstants.dashboard);
        } else {
          context.go(RouteConstants.landing);
        }
      },
      loading: () {
        // Wait for loading to complete, the listener will handle it or we retry
        // In this architecture, AuthNotifier inits immediately, so loading might be brief
      },
      error: (e, st) {
        // On error, safely default to landing to allow login attempt
        context.go(RouteConstants.landing);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to react immediately if state updates while on splash
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          context.go(RouteConstants.dashboard);
        } else {
          context.go(RouteConstants.landing);
        }
      });
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(
              'Arun Sharma Vastu Consultancy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
