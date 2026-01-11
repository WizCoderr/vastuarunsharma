import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../domain/entities/course.dart';

/// State class for video player
class VideoPlayerState {
  final Player player;
  final VideoController controller;
  final Lecture? currentLecture;
  final bool isBuffering;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;
  final String? errorMessage;

  VideoPlayerState({
    required this.player,
    required this.controller,
    this.currentLecture,
    this.isBuffering = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isFullscreen = false,
    this.errorMessage,
  });

  VideoPlayerState copyWith({
    Player? player,
    VideoController? controller,
    Lecture? currentLecture,
    bool? isBuffering,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
    String? errorMessage,
  }) {
    return VideoPlayerState(
      player: player ?? this.player,
      controller: controller ?? this.controller,
      currentLecture: currentLecture ?? this.currentLecture,
      isBuffering: isBuffering ?? this.isBuffering,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for video player state management
class VideoPlayerNotifier extends Notifier<VideoPlayerState?> {
  Player? _player;
  VideoController? _controller;

  @override
  VideoPlayerState? build() {
    ref.onDispose(() {
      _player?.dispose();
    });
    return null;
  }

  /// Initialize the player with a video URL
  Future<void> initialize(String videoUrl, Lecture lecture) async {
    // Dispose existing player if any
    await disposePlayer();

    // Create new player
    _player = Player();
    _controller = VideoController(_player!);

    state = VideoPlayerState(
      player: _player!,
      controller: _controller!,
      currentLecture: lecture,
      isBuffering: true,
    );

    // Listen to player streams
    _setupListeners();

    // Open the media
    try {
      await _player!.open(Media(videoUrl));
    } catch (e) {
      state = state?.copyWith(
        errorMessage: 'Failed to load video: ${e.toString()}',
        isBuffering: false,
      );
    }
  }

  void _setupListeners() {
    // Playing state
    _player!.stream.playing.listen((playing) {
      state = state?.copyWith(isPlaying: playing);
    });

    // Buffering state
    _player!.stream.buffering.listen((buffering) {
      state = state?.copyWith(isBuffering: buffering);
    });

    // Position
    _player!.stream.position.listen((position) {
      state = state?.copyWith(position: position);
    });

    // Duration
    _player!.stream.duration.listen((duration) {
      state = state?.copyWith(duration: duration);
    });

    // Volume
    _player!.stream.volume.listen((volume) {
      state = state?.copyWith(volume: volume / 100);
    });

    // Errors
    _player!.stream.error.listen((error) {
      if (error.isNotEmpty) {
        state = state?.copyWith(errorMessage: error);
      }
    });
  }

  /// Play the video
  void play() {
    _player?.play();
  }

  /// Pause the video
  void pause() {
    _player?.pause();
  }

  /// Stop the video
  Future<void> stop() async {
    await _player?.stop();
    state = state?.copyWith(isPlaying: false, position: Duration.zero);
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (state?.isPlaying ?? false) {
      pause();
    } else {
      play();
    }
  }

  /// Seek to position
  void seek(Duration position) {
    _player?.seek(position);
  }

  /// Seek forward by seconds
  void seekForward(int seconds) {
    final currentPosition = state?.position ?? Duration.zero;
    final duration = state?.duration ?? Duration.zero;
    final newPosition = currentPosition + Duration(seconds: seconds);
    if (newPosition < duration) {
      seek(newPosition);
    } else {
      seek(duration);
    }
  }

  /// Seek backward by seconds
  void seekBackward(int seconds) {
    final currentPosition = state?.position ?? Duration.zero;
    final newPosition = currentPosition - Duration(seconds: seconds);
    if (newPosition > Duration.zero) {
      seek(newPosition);
    } else {
      seek(Duration.zero);
    }
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _player?.setVolume(volume * 100);
  }

  /// Toggle mute
  void toggleMute() {
    if ((state?.volume ?? 0) > 0) {
      setVolume(0);
    } else {
      setVolume(1.0);
    }
  }

  /// Set fullscreen state
  void setFullscreen(bool isFullscreen) {
    state = state?.copyWith(isFullscreen: isFullscreen);
  }

  /// Change lecture
  Future<void> changeLecture(String videoUrl, Lecture lecture) async {
    state = state?.copyWith(
      currentLecture: lecture,
      isBuffering: true,
      errorMessage: null,
    );

    try {
      await _player?.open(Media(videoUrl));
    } catch (e) {
      state = state?.copyWith(
        errorMessage: 'Failed to load video: ${e.toString()}',
        isBuffering: false,
      );
    }
  }

  /// Dispose the player
  Future<void> disposePlayer() async {
    await _player?.dispose();
    _player = null;
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
