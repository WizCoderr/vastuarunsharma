import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/providers/video_player_provider.dart';

class CustomVideoPlayer extends ConsumerStatefulWidget {
  final bool showControls;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback? onPipToggle;

  const CustomVideoPlayer({
    super.key,
    this.showControls = true,
    this.onFullscreenToggle,
    this.onPipToggle,
  });

  @override
  ConsumerState<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends ConsumerState<CustomVideoPlayer> {
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (ref.read(videoPlayerProvider)?.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    ref.read(videoPlayerProvider.notifier).setFullscreen(_isFullscreen);
    widget.onFullscreenToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(videoPlayerProvider);

    if (playerState == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (playerState.errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  playerState.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry logic can be added here
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video
            Center(
              child: Video(
                controller: playerState.controller,
                controls: NoVideoControls,
              ),
            ),

            // Buffering indicator
            if (playerState.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            if (widget.showControls && _showControls)
              _buildControlsOverlay(playerState),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(VideoPlayerState playerState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top bar
            _buildTopBar(playerState),
            // Center controls
            _buildCenterControls(playerState),
            // Bottom bar
            _buildBottomBar(playerState),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(VideoPlayerState playerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (_isFullscreen)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _toggleFullscreen,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (_isFullscreen) const SizedBox(width: 8),
          Expanded(
            child: Text(
              playerState.currentLecture?.title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // PiP button
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
            onPressed: widget.onPipToggle,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(VideoPlayerState playerState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10, color: Colors.white),
          onPressed: () {
            ref.read(videoPlayerProvider.notifier).seekBackward(10);
          },
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        // Play/Pause
        IconButton(
          iconSize: 48,
          icon: Icon(
            playerState.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.white,
          ),
          onPressed: () {
            ref.read(videoPlayerProvider.notifier).togglePlayPause();
          },
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        // Forward 10s
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_10, color: Colors.white),
          onPressed: () {
            ref.read(videoPlayerProvider.notifier).seekForward(10);
          },
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildBottomBar(VideoPlayerState playerState) {
    final position = playerState.position;
    final duration = playerState.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white30,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.3),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).toInt(),
                );
                ref.read(videoPlayerProvider.notifier).seek(newPosition);
              },
            ),
          ),
          // Time and controls row
          Row(
            children: [
              // Current time / Duration
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const Spacer(),
              // Volume
              IconButton(
                icon: Icon(
                  playerState.volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  ref.read(videoPlayerProvider.notifier).toggleMute();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              // Fullscreen
              IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _toggleFullscreen,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation when widget is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
