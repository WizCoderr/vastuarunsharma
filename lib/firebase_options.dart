// Generated from ios/Runner/GoogleService-Info.plist and
// android/app/google-services.json.
// Regenerate with `flutterfire configure` when Firebase config changes.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for Firebase.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Platform $defaultTargetPlatform is not configured for Firebase.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBawQKOEQBGB2mWHyQQKmCgQ9_nuqYAis8',
    appId: '1:996974323504:android:93aa6f5c09202090d00af5',
    messagingSenderId: '996974323504',
    projectId: 'vastunotification',
    storageBucket: 'vastunotification.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWEpV4dL25fi6sAvHuMn3an7fAz5a1XPw',
    appId: '1:996974323504:ios:5cc913ba5c2aa002d00af5',
    messagingSenderId: '996974323504',
    projectId: 'vastunotification',
    storageBucket: 'vastunotification.firebasestorage.app',
    iosBundleId: 'com.vastuarunsharma.vastumobile',
  );
}
