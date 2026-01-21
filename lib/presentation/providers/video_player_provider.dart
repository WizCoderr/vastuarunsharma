import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
      _controller?.dispose();
    });
    return null;
  }

  /// Initialize the player with a video URL
  void initialize(String videoUrl, Lecture lecture) {
    // Extract ID
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      state = VideoPlayerState(
        errorMessage: 'Invalid YouTube URL',
        currentLecture: lecture,
      );
      return;
    }

    // Dispose existing if any
    _controller?.dispose();

    // Create new controller
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
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
    _controller?.addListener(() {
      if (_controller == null || !_controller!.value.isReady) return;

      final value = _controller!.value;

      // Check for completion
      // YoutubePlayerController doesn't have a direct 'completed' event stream in the same way,
      // but we can check playerState.
      final isEnded = value.playerState == PlayerState.ended;

      state = state?.copyWith(
        isPlaying: value.isPlaying,
        isBuffering: value.playerState == PlayerState.buffering,
        position: value.position,
        duration: value.metaData.duration,
        volume: value.volume.toDouble(),
        // Check fullscreen from controller?? No, usually managed by UI wrapper in flutter youtube player
        // But we store it here for UI sync
        isCompleted: isEnded,
        errorMessage: value.hasError
            ? 'Playback Error: ${value.errorCode}'
            : null,
      );
    });
  }

  void play() {
    _controller?.play();
  }

  void pause() {
    _controller?.pause();
  }

  void stop() {
    _controller?.pause();
    // Youtube player doesn't have stop? usually pause and seek to 0
    _controller?.seekTo(Duration.zero);
    state = state?.copyWith(isPlaying: false, position: Duration.zero);
  }

  void togglePlayPause() {
    if (state?.isPlaying ?? false) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration position) {
    _controller?.seekTo(position);
  }

  void seekForward(int seconds) {
    final current = state?.position ?? Duration.zero;
    final total = state?.duration ?? Duration.zero;
    final newPos = current + Duration(seconds: seconds);
    seek(newPos < total ? newPos : total);
  }

  void seekBackward(int seconds) {
    final current = state?.position ?? Duration.zero;
    final newPos = current - Duration(seconds: seconds);
    seek(newPos > Duration.zero ? newPos : Duration.zero);
  }

  void setVolume(double volume) {
    _controller?.setVolume(volume.toInt());
  }

  void toggleMute() {
    if ((state?.volume ?? 0) > 0) {
      _controller?.mute();
    } else {
      _controller?.unMute();
      setVolume(100);
    }
  }

  void setFullscreen(bool isFullscreen) {
    state = state?.copyWith(isFullscreen: isFullscreen);
  }

  void reload(String videoUrl, Lecture lecture) {
    initialize(videoUrl, lecture);
  }

  void disposePlayer() {
    _controller?.dispose();
    _controller = null;
    state = null;
  }
}

/// Provider for video player
final videoPlayerProvider =
    NotifierProvider<VideoPlayerNotifier, VideoPlayerState?>(() {
      return VideoPlayerNotifier();
    });

/// Provider for current lecture index in a course
final currentLectureIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for current section index in a course
final currentSectionIndexProvider = StateProvider<int>((ref) => 0);
