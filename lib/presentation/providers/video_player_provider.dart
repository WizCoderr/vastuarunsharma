import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/utils/youtube_url_utils.dart';
import '../../domain/entities/course.dart';

/// State class for video player
class VideoPlayerState {
  final YoutubePlayerController? controller;
  final Lecture? currentLecture;
  final bool isBuffering;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;
  final bool isCompleted;
  final String? errorMessage;

  VideoPlayerState({
    this.controller,
    this.currentLecture,
    this.isBuffering = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.isFullscreen = false,
    this.isCompleted = false,
    this.errorMessage,
  });

  VideoPlayerState copyWith({
    YoutubePlayerController? controller,
    Lecture? currentLecture,
    bool? isBuffering,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return VideoPlayerState(
      controller: controller ?? this.controller,
      currentLecture: currentLecture ?? this.currentLecture,
      isBuffering: isBuffering ?? this.isBuffering,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for video player state management
class VideoPlayerNotifier extends Notifier<VideoPlayerState?> {
  YoutubePlayerController? _controller;

  @override
  VideoPlayerState? build() {
    ref.onDispose(() {
      _controller?.close();
    });
    return null;
  }

  /// Initialize the player with a video URL
  void initialize(String videoUrl, Lecture lecture) {
    // Extract ID safely from any YouTube URL format
    final videoId = YoutubeUrlUtils.extractVideoId(videoUrl);
    if (videoId == null) {
      state = VideoPlayerState(
        errorMessage: 'Invalid YouTube URL: $videoUrl',
        currentLecture: lecture,
      );
      return;
    }

    // Dispose existing if any
    _controller?.close();

    // Use the canonical fromVideoId factory (recommended by youtube_player_iframe)
    // with autoPlay: true so the video starts immediately after the player is ready.
    // CRITICAL: origin must be 'https://www.youtube-nocookie.com' to avoid
    // Error 150/152 on unlisted/restricted videos.
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        playsInline: true,
        enableJavaScript: true,
        enableCaption: true,
        // CRITICAL: youtube-nocookie.com prevents embedding restriction errors
        origin: 'https://www.youtube-nocookie.com',
      ),
    );

    // Initial state
    state = VideoPlayerState(
      controller: _controller,
      currentLecture: lecture,
      isBuffering: true,
    );

    _setupListeners();
  }

  void _setupListeners() {
    // Listen to video state changes
    _controller?.setFullScreenListener((isFullScreen) {
      state = state?.copyWith(isFullscreen: isFullScreen);
    });

    if (_controller != null) {
      Stream<YoutubePlayerValue> stream = _controller!.stream;

      stream.listen((value) {
        final isPlaying = value.playerState == PlayerState.playing;
        final isBuffering = value.playerState == PlayerState.buffering;
        final isCompleted = value.playerState == PlayerState.ended;

        // Only update if state changed to avoid unnecessary rebuilds
        if (state?.isPlaying != isPlaying ||
            state?.isBuffering != isBuffering ||
            state?.isCompleted != isCompleted) {
          state = state?.copyWith(
            isPlaying: isPlaying,
            isBuffering: isBuffering,
            isCompleted: isCompleted,
            duration: value.metaData.duration, // Update duration if available
          );
        }
      });
    }
  }

  void play() {
    _controller?.playVideo();
  }

  void pause() {
    _controller?.pauseVideo();
  }

  void stop() {
    _controller?.stopVideo();
    state = state?.copyWith(isPlaying: false, position: Duration.zero);
  }

  void togglePlayPause() async {
    final state = await _controller?.playerState;
    if (state == PlayerState.playing) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration position) {
    _controller?.seekTo(seconds: position.inSeconds.toDouble());
  }

  void setFullscreen(bool isFullscreen) {
    if (isFullscreen) {
      _controller?.enterFullScreen();
    } else {
      _controller?.exitFullScreen();
    }
    state = state?.copyWith(isFullscreen: isFullscreen);
  }

  void disposePlayer() {
    _controller?.close();
    _controller = null;
    // Delay state update to avoid 'modify provider during build' error
    // when called from widget dispose()
    Future.microtask(() {
      state = null;
    });
  }
}

/// Provider for video player
final videoPlayerProvider =
    NotifierProvider<VideoPlayerNotifier, VideoPlayerState?>(() {
      return VideoPlayerNotifier();
    });

/// Provider for current lecture index in a course
final currentLectureIndexProvider = NotifierProvider<LectureIndexNotifier, int>(
  () {
    return LectureIndexNotifier();
  },
);

class LectureIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

/// Provider for current section index in a course
final currentSectionIndexProvider = NotifierProvider<SectionIndexNotifier, int>(
  () {
    return SectionIndexNotifier();
  },
);

class SectionIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}
