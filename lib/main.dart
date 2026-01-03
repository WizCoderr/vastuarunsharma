import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  print('DEBUG: Raw Token: ${prefs.getString('auth_token')}');
  print('DEBUG: Raw User Data: ${prefs.getString('user_data')}');

  runApp(
    ProviderScope(
      overrides: [
        // Override the provider to use the initialized instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VastuApp(),
    ),
  );
}
