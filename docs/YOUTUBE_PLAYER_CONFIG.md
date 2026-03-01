# YouTube Player Iframe Configuration Guide

This document explains how to fix YouTube Player errors **152** and **-4** when playing unlisted videos in Flutter.

## Error Codes Explained

| Error Code | Meaning | Common Cause |
|------------|---------|--------------|
| **152** | "Playback not allowed" | Embedding disabled in YouTube Studio or domain restrictions |
| **-4** | "Video unavailable" | Privacy/embedding settings or platform configuration issues |

## Required YouTube Studio Settings

1. Go to **YouTube Studio** → Select your video
2. Click **Details** → Scroll to "Video details"
3. Under **Visibility**, ensure video is **Public** or **Unlisted**
4. Click **Options** (gear icon) → Advanced settings
5. Ensure **"Allow embedding"** is **ENABLED**
6. Save changes

### Domain Restrictions (if using)

If you've set allowed domains in YouTube Studio:
- Add `https://www.youtube.com`
- For Android/iOS apps, embedding restrictions may not apply the same way as web

## Android Configuration

### 1. AndroidManifest.xml

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="Your App Name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        <!-- CRITICAL: Required for WebView media playback -->
        android:usesCleartextTraffic="true"
        android:hardwareAccelerated="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Don't delete the meta-data below -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <!-- Required for WebView text processing -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

### Key Android Settings:

1. **`android:usesCleartextTraffic="true"`**: Required for WebView communication with YouTube
2. **`android:hardwareAccelerated="true"`**: Essential for video rendering
3. **`android:configChanges`**: Must include orientation changes for fullscreen

### 2. ProGuard Rules (for release builds)

Add to `android/app/proguard-rules.pro`:

```proguard
# WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebView
-keep class android.webkit.** { *; }
-keep class androidx.webkit.** { *; }

# YouTube player
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.google.android.gms.** { *; }
```

### 3. Minimum SDK Version

Ensure in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for WebView
        targetSdkVersion 34
    }
}
```

## iOS Configuration

### 1. Info.plist

Update `ios/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Standard Flutter entries... -->

    <!-- CRITICAL: Allow arbitrary loads for WebView/YouTube -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsArbitraryLoadsInWebContent</key>
        <true/>
    </dict>

    <!-- Required for video playback -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>

    <!-- Orientation support -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <!-- Required for WebView -->
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
</dict>
</plist>
```

### Key iOS Settings:

1. **`NSAllowsArbitraryLoads`**: Allows WebView to load YouTube content
2. **`UIBackgroundModes` with `audio`**: Required for background audio
3. **Orientation support**: Required for fullscreen video

### 2. Podfile Configuration

Ensure `ios/Podfile` has minimum iOS version:

```ruby
platform :ios, '12.0'  # Minimum required for WebView features
```

## Flutter Implementation

### Minimal Working Example

```dart
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerWidget({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        // Essential settings
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,

        // Critical for mobile
        playsInline: true,
        enableJavaScript: true,

        // Helps with embedding
        origin: 'https://www.youtube.com',
        enableCaption: true,
      ),
    );

    if (videoId != null) {
      _controller.loadVideoById(videoId: videoId);
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
  }
}
```

### Player Parameters Reference

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `showControls` | `true` | Show player controls |
| `showFullscreenButton` | `false` | Show fullscreen button |
| `strictRelatedVideos` | `false` | Show only same-channel related videos |
| `playsInline` | `true` | Play inline (not fullscreen) on iOS |
| `enableJavaScript` | `true` | Required for player API |
| `origin` | `'https://www.youtube.com'` | Referrer for embedding |
| `enableCaption` | `true` | Show captions by default |
| `mute` | `false` | Start muted (helps with autoplay) |

## Troubleshooting Checklist

### For Error 152:

- [ ] Video is Public or Unlisted (not Private)
- [ ] "Allow embedding" is enabled in YouTube Studio
- [ ] Video doesn't have age restrictions that prevent embedding
- [ ] Video isn't blocked in certain regions

### For Error -4:

- [ ] Android: `usesCleartextTraffic="true"` in manifest
- [ ] Android: `hardwareAccelerated="true"` in manifest
- [ ] iOS: `NSAllowsArbitraryLoads` in Info.plist
- [ ] Video URL is valid and extractable
- [ ] Device has internet connection

### For Both Errors:

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter run
   ```

2. **Check package version:**
   ```yaml
   dependencies:
     youtube_player_iframe: ^5.2.2  # or latest
   ```

3. **Test with a known working video:**
   - Try: `https://www.youtube.com/watch?v=dQw4w9WgXcQ` (Rick Astley - always embeddable)

4. **Check WebView implementation:**
   The package uses `flutter_inappwebview` internally. Ensure it's properly configured.

## Testing Commands

```bash
# Clean everything
flutter clean && rm -rf ios/Pods ios/Podfile.lock android/.gradle

# Reinstall dependencies
flutter pub get
cd ios && pod install --repo-update && cd ..

# Run with verbose output
flutter run -v

# Check for dependency issues
flutter doctor -v
```

## Additional Notes

### For Unlisted Videos Specifically:

1. Unlisted videos should work with embedding enabled
2. The video ID must be extracted correctly (11 characters)
3. Some unlisted videos may still have restrictions from the uploader

### For Private Videos:

Private videos **cannot** be played via the iframe player. They must be:
- Changed to Unlisted, OR
- Played through YouTube app via URL launcher

### Alternative for Restricted Videos:

If embedding is disabled and you cannot change it:

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openInYoutubeApp(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

## References

- [youtube_player_iframe package](https://pub.dev/packages/youtube_player_iframe)
- [YouTube IFrame API Docs](https://developers.google.com/youtube/iframe_api_reference)
- [WebView Android Docs](https://developer.android.com/reference/android/webkit/WebView)
- [iOS WebKit Docs](https://developer.apple.com/documentation/webkit/wkwebview)
