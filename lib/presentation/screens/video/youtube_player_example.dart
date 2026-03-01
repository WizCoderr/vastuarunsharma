import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/utils/youtube_url_utils.dart';

/// Minimal working example for playing unlisted YouTube videos
/// with proper configuration to prevent error 152 and -4
///
/// ERROR CODES EXPLANATION:
/// - Error 152: "Playback not allowed" - Usually occurs when embedding is disabled
///   or the video has domain restrictions
/// - Error -4: "Video not available" - Often happens with unlisted/private videos
///   when origin/referrer settings are incorrect
///
/// REQUIRED PLATFORM CONFIGURATIONS (see below):
/// 1. Android: AndroidManifest.xml must include proper WebView settings
/// 2. iOS: Info.plist must include ATS exceptions
class YoutubePlayerExample extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;

  const YoutubePlayerExample({
    super.key,
    required this.videoUrl,
    this.videoTitle,
  });

  @override
  State<YoutubePlayerExample> createState() => _YoutubePlayerExampleState();
}

class _YoutubePlayerExampleState extends State<YoutubePlayerExample> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    // Extract video ID from URL
    final videoId = YoutubeUrlUtils.extractVideoId(widget.videoUrl);

    if (videoId == null) {
      setState(() {
        _error = 'Invalid YouTube URL: ${widget.videoUrl}';
        _isLoading = false;
      });
      return;
    }

    // Use the canonical fromVideoId factory with autoPlay
    // CRITICAL: origin must be youtube-nocookie.com for unlisted videos
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        enableCaption: true,
        playsInline: true,
        enableJavaScript: true,
        // CRITICAL: Prevents Error 150/152 for unlisted/restricted videos
        origin: 'https://www.youtube-nocookie.com',
      ),
    );

    // Listen for player events
    _controller!.stream.listen(
      (event) {
        debugPrint('Player state: ${event.playerState}');
        if (event.playerState == PlayerState.ended) {
          debugPrint('Video ended');
        }
      },
      onError: (error) {
        setState(() {
          _error = 'Player error: $error';
          _isLoading = false;
        });
      },
    );

    // Mark as loaded after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_isLoading || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      aspectRatio: 16 / 9,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Common fixes:\n'
            '1. Enable embedding in YouTube Studio\n'
            '2. Check if video is public/unlisted\n'
            '3. Verify Android/iOS configs (see documentation)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _initializePlayer();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Alternative: Using cueVideoById for unlisted videos
/// This can sometimes work better for restricted videos
class YoutubePlayerCueExample extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerCueExample({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerCueExample> createState() => _YoutubePlayerCueExampleState();
}

class _YoutubePlayerCueExampleState extends State<YoutubePlayerCueExample> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubeUrlUtils.extractVideoId(widget.videoUrl);

    // Use fromVideoId with autoPlay: false to cue (not auto-start) the video
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        playsInline: true,
        enableCaption: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
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

/// Fullscreen video player widget
class FullscreenYoutubePlayer extends StatelessWidget {
  final String videoUrl;
  final String? title;

  const FullscreenYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.title,
  });

  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
    String? title,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenYoutubePlayer(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          title ?? 'Video Player',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: YoutubePlayerExample(videoUrl: videoUrl),
      ),
    );
  }
}
