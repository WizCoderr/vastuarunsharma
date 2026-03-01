/// Utility class for safely extracting YouTube video IDs from various URL formats.
///
/// Supports:
/// - `https://www.youtube.com/watch?v=VIDEO_ID`
/// - `https://youtu.be/VIDEO_ID`
/// - `https://www.youtube.com/embed/VIDEO_ID`
/// - `https://www.youtube.com/v/VIDEO_ID`
/// - `https://youtube.com/shorts/VIDEO_ID`
/// - Raw video ID strings (11 characters, alphanumeric + `-_`)
///
/// Returns `null` for invalid, empty, or malformed URLs.
class YoutubeUrlUtils {
  YoutubeUrlUtils._(); // Prevent instantiation

  /// Valid YouTube video ID pattern: 11 characters, alphanumeric + hyphen + underscore
  static final RegExp _videoIdPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Extracts a YouTube video ID from [url].
  ///
  /// Returns `null` if [url] is null, empty, or cannot be parsed into a valid video ID.
  ///
  /// Example:
  /// ```dart
  /// YoutubeUrlUtils.extractVideoId('https://www.youtube.com/watch?v=AbCdEf12345');
  /// // Returns 'AbCdEf12345'
  ///
  /// YoutubeUrlUtils.extractVideoId('https://youtu.be/AbCdEf12345');
  /// // Returns 'AbCdEf12345'
  ///
  /// YoutubeUrlUtils.extractVideoId(null);
  /// // Returns null
  /// ```
  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();

    // If it's already a raw video ID (11 chars, valid pattern)
    if (_videoIdPattern.hasMatch(trimmed)) {
      return trimmed;
    }

    // Try parsing as a URI
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    String? videoId;

    // Handle youtu.be short links
    if (uri.host == 'youtu.be' || uri.host == 'www.youtu.be') {
      // Path is /VIDEO_ID
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        videoId = segments.first;
      }
    }
    // Handle youtube.com variants
    else if (uri.host.contains('youtube.com') || uri.host.contains('youtube-nocookie.com')) {
      final segments = uri.pathSegments;

      if (segments.isNotEmpty) {
        // /watch — video ID is in the query parameter 'v'
        if (segments.first == 'watch') {
          videoId = uri.queryParameters['v'];
        }
        // /embed/VIDEO_ID, /v/VIDEO_ID, /shorts/VIDEO_ID
        else if (segments.length >= 2 &&
            (segments.first == 'embed' ||
                segments.first == 'v' ||
                segments.first == 'shorts')) {
          videoId = segments[1];
        }
      }

      // Fallback: check 'v' query parameter even if path doesn't start with /watch
      videoId ??= uri.queryParameters['v'];
    }

    // Validate extracted ID
    if (videoId != null && _videoIdPattern.hasMatch(videoId)) {
      return videoId;
    }

    return null;
  }

  /// Returns `true` if [url] contains a valid YouTube video ID.
  static bool isValidYoutubeUrl(String? url) {
    return extractVideoId(url) != null;
  }
}
