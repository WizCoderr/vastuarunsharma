import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/live_class.dart';
import '../../../shared/widgets/custom_video_player.dart';
import '../../providers/course_provider.dart';
import '../../providers/live_class_provider.dart';
import '../../providers/pip_provider.dart';
import '../../providers/stream_url_provider.dart';
import '../../providers/video_player_provider.dart';
import 'live_session_redirect_screen.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String? initialLectureId;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    this.initialLectureId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  Lecture? _currentLecture;
  int _currentSectionIndex = 0;
  int _currentLectureIndex = 0;
  bool _isFullscreen = false;
  LiveClass? _availableLiveClass;
  bool _isLoadingContent = false;

  // Store reference to avoid using ref in dispose()
  late final VideoPlayerNotifier _videoPlayerNotifier;

  @override
  void initState() {
    super.initState();
    _videoPlayerNotifier = ref.read(videoPlayerProvider.notifier);
  }

  @override
  void dispose() {
    _videoPlayerNotifier.disposePlayer();
    super.dispose();
  }

  Future<void> _loadLecture(Lecture lecture) async {
    setState(() {
      _currentLecture = lecture;
      _isLoadingContent = true;
      _availableLiveClass = null; // Reset live class
    });

    String? videoUrl;

    // Try to get cached stream URL first
    try {
      final streamUrl = await ref.read(
        cachedStreamUrlProvider(lecture.id).future,
      );
      if (streamUrl.url.isNotEmpty) {
        videoUrl = streamUrl.url;
      }
    } catch (e) {
      // Ignore cache error, fallback to lecture.videoUrl
    }

    // Fallback to direct video URL if cache failed or returned empty
    if (videoUrl == null || videoUrl.isEmpty) {
      if (lecture.videoUrl.isNotEmpty) {
        videoUrl = lecture.videoUrl;
      }
    }

    // If we still don't have a valid video URL, check for live classes
    if (videoUrl == null || videoUrl.isEmpty) {
      debugPrint(
        'No video URL found for lecture ${lecture.id}. Checking for live classes...',
      );
      try {
        // Fetch today's and upcoming live classes
        final todayClasses = await ref.read(todayLiveClassesProvider.future);
        final upcomingClasses = await ref.read(
          upcomingLiveClassesProvider.future,
        );

        // Combine and find a relevant live class for this course
        // Currently, we just show any live class for this course as a fallback,
        // ideally we might match strictly by schedule if the lecture metadata had it.
        // For now, we prioritize:
        // 1. Live/Scheduled classes for this specific course

        final courseLiveClasses = [
          ...todayClasses,
          ...upcomingClasses,
        ].where((liveClass) => liveClass.courseId == widget.courseId).toList();

        // Sort by start time: Live now first, then soonest upcoming
        courseLiveClasses.sort((a, b) {
          // If statuses differ, prioritize LIVE
          if (a.status == 'LIVE' && b.status != 'LIVE') return -1;
          if (b.status == 'LIVE' && a.status != 'LIVE') return 1;
          // Otherwise sort by scheduled time
          return a.scheduledAt.compareTo(b.scheduledAt);
        });

        if (courseLiveClasses.isNotEmpty) {
          setState(() {
            _availableLiveClass = courseLiveClasses.first;
            _isLoadingContent = false;
          });
          // Stop player if it was running
          await ref.read(videoPlayerProvider.notifier).stop();
          return;
        }
      } catch (e) {
        debugPrint('Error fetching live classes: $e');
      }
    }

    // If we have a video URL (or even if we don't and found no live class), initialize player
    // If videoUrl is still empty here, the player handles it (shows error/loading depending on impl)
    await ref
        .read(videoPlayerProvider.notifier)
        .initialize(videoUrl ?? '', lecture);

    setState(() {
      _isLoadingContent = false;
    });
  }

  void _playLecture(Course course, int sectionIndex, int lectureIndex) {
    final section = course.sections[sectionIndex];
    final lecture = section.lectures[lectureIndex];

    setState(() {
      _currentSectionIndex = sectionIndex;
      _currentLectureIndex = lectureIndex;
    });

    _loadLecture(lecture);
  }

  void _playNextLecture(Course course) {
    final currentSection = course.sections[_currentSectionIndex];

    if (_currentLectureIndex < currentSection.lectures.length - 1) {
      _playLecture(course, _currentSectionIndex, _currentLectureIndex + 1);
    } else {
      // Find next section with lectures
      for (int i = _currentSectionIndex + 1; i < course.sections.length; i++) {
        if (course.sections[i].lectures.isNotEmpty) {
          _playLecture(course, i, 0);
          return;
        }
      }
    }
  }

  void _playPreviousLecture(Course course) {
    if (_currentLectureIndex > 0) {
      _playLecture(course, _currentSectionIndex, _currentLectureIndex - 1);
    } else {
      // Find previous section with lectures
      for (int i = _currentSectionIndex - 1; i >= 0; i--) {
        if (course.sections[i].lectures.isNotEmpty) {
          final prevSection = course.sections[i];
          _playLecture(course, i, prevSection.lectures.length - 1);
          return;
        }
      }
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  Future<void> _enterPipMode() async {
    final pipNotifier = ref.read(pipProvider.notifier);
    await pipNotifier.enterPipMode(width: 16, height: 9);
  }

  int _getTotalLectures(Course course) {
    return course.sections.fold(
      0,
      (sum, section) => sum + section.lectures.length,
    );
  }

  int _getCurrentLectureNumber(Course course) {
    int count = 0;
    for (int i = 0; i < _currentSectionIndex; i++) {
      count += course.sections[i].lectures.length;
    }
    return count + _currentLectureIndex + 1;
  }

  bool _canPlayPrevious(Course course) {
    if (_currentLectureIndex > 0) return true;
    // Check if any previous section has lectures
    for (int i = _currentSectionIndex - 1; i >= 0; i--) {
      if (course.sections[i].lectures.isNotEmpty) return true;
    }
    return false;
  }

  bool _canPlayNext(Course course) {
    final currentSection = course.sections[_currentSectionIndex];
    if (_currentLectureIndex < currentSection.lectures.length - 1) return true;

    // Check if any subsequent section has lectures
    for (int i = _currentSectionIndex + 1; i < course.sections.length; i++) {
      if (course.sections[i].lectures.isNotEmpty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));
    final isInPipMode = ref.watch(isInPipModeProvider);

    if (isInPipMode) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: CustomVideoPlayer(showControls: false),
      );
    }

    if (_isFullscreen) {
      // If we are showing live class info instead of video, fullscreen doesn't make sense
      // But if somehow triggered, handle gracefully
      if (_availableLiveClass != null) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: LiveSessionRedirectScreen(liveClass: _availableLiveClass!),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: CustomVideoPlayer(
          showControls: true,
          onFullscreenToggle: _toggleFullscreen,
          onPipToggle: _enterPipMode,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RouteConstants.courseDetailsPath(widget.courseId));
            }
          },
        ),
        title: courseAsync.when(
          data: (course) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Lecture ${_getCurrentLectureNumber(course)} of ${_getTotalLectures(course)}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          loading: () =>
              const Text('Loading...', style: TextStyle(color: Colors.white)),
          error: (error, stack) =>
              const Text('Error', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: courseAsync.when(
        data: (course) => _buildContent(course),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, stack) => _buildError(error),
      ),
    );
  }

  Widget _buildContent(Course course) {
    if (course.sections.isEmpty) {
      return const Center(
        child: Text(
          'No lectures available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_currentLecture == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialLectureId != null) {
          _findAndPlayLecture(course, widget.initialLectureId!);
        } else {
          _playFirstAvailableLecture(course);
        }
      });
    }

    return Column(
      children: [
        // Video Player Area
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _isLoadingContent
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _availableLiveClass != null
              ? LiveSessionRedirectScreen(liveClass: _availableLiveClass!)
              : CustomVideoPlayer(
                  showControls: true,
                  onFullscreenToggle: _toggleFullscreen,
                  onPipToggle: _enterPipMode,
                ),
        ),

        // Course Info Header
        _buildCourseInfoHeader(course),

        // Lecture navigation
        _buildNavigationControls(course),

        // Course Content List
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: course.sections.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.secondaryVariant.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              itemBuilder: (context, sectionIndex) {
                final section = course.sections[sectionIndex];
                return _buildSectionTile(course, sectionIndex, section);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Placeholder removed, using LiveSessionRedirectScreen

  Widget _buildCourseInfoHeader(Course course) {
    final totalLectures = _getTotalLectures(course);
    final currentLecture = _getCurrentLectureNumber(course);
    final progress = totalLectures > 0 ? currentLecture / totalLectures : 0.0;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Progress indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lecture $currentLecture of $totalLectures',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.secondaryVariant,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${course.sections.length} Sections',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(Course course) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Previous button
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: _canPlayPrevious(course)
                    ? Colors.white
                    : Colors.grey[600],
              ),
              onPressed: _canPlayPrevious(course)
                  ? () => _playPreviousLecture(course)
                  : null,
              iconSize: 22,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),

          // Current lecture info
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentLecture?.title ?? 'Select a lecture',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _canPlayNext(course)
                  ? AppColors.primary
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.skip_next,
                color: _canPlayNext(course) ? Colors.white : Colors.grey[600],
              ),
              onPressed: _canPlayNext(course)
                  ? () => _playNextLecture(course)
                  : null,
              iconSize: 22,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(Course course, int sectionIndex, Section section) {
    final isCurrentSection = sectionIndex == _currentSectionIndex;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isCurrentSection,
        backgroundColor: AppColors.background,
        collapsedBackgroundColor: Colors.white,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.grey[600],
        title: Row(
          children: [
            // Section number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCurrentSection
                    ? AppColors.primary
                    : AppColors.secondaryVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${sectionIndex + 1}',
                  style: TextStyle(
                    color: isCurrentSection ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Text(
              '${section.lectures.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        children: section.lectures.asMap().entries.map((entry) {
          final lectureIndex = entry.key;
          final lecture = entry.value;
          final isPlaying = _currentLecture?.id == lecture.id;

          return _buildEnhancedLectureTile(
            course,
            sectionIndex,
            lectureIndex,
            lecture,
            isPlaying,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedLectureTile(
    Course course,
    int sectionIndex,
    int lectureIndex,
    Lecture lecture,
    bool isPlaying,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.secondaryVariant.withOpacity(0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlaying ? AppColors.primary : Colors.grey.shade200,
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _playLecture(course, sectionIndex, lectureIndex),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Play icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying ? AppColors.primary : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isPlaying ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Lecture info
              Expanded(
                child: Text(
                  lecture.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
                    color: isPlaying ? AppColors.primary : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Provider badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lecture.videoProvider,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _findAndPlayLecture(Course course, String lectureId) {
    for (
      int sectionIndex = 0;
      sectionIndex < course.sections.length;
      sectionIndex++
    ) {
      final section = course.sections[sectionIndex];
      for (
        int lectureIndex = 0;
        lectureIndex < section.lectures.length;
        lectureIndex++
      ) {
        if (section.lectures[lectureIndex].id == lectureId) {
          _playLecture(course, sectionIndex, lectureIndex);
          return;
        }
      }
    }
    _playFirstAvailableLecture(course);
  }

  void _playFirstAvailableLecture(Course course) {
    // 1. Check for standard lectures
    for (int i = 0; i < course.sections.length; i++) {
      if (course.sections[i].lectures.isNotEmpty) {
        _playLecture(course, i, 0);
        return;
      }
    }

    // 2. If no lectures, check for Live Classes (Course level or Section level)
    final allLiveClasses = [
      ...course.liveClasses,
      ...course.sections.expand((s) => s.liveClasses),
    ];

    if (allLiveClasses.isNotEmpty) {
      // Sort to find the most relevant one (Live > Scheduled soon)
      allLiveClasses.sort((a, b) {
        if (a.status == 'LIVE' && b.status != 'LIVE') return -1;
        if (b.status == 'LIVE' && a.status != 'LIVE') return 1;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

      setState(() {
        _availableLiveClass = allLiveClasses.first;
        _isLoadingContent = false;
      });
      return;
    }

    // 3. Fallback to older live class lookup logic (provider) if model didn't have it
    // (This part matches the existing _loadLecture fallback, but here we are initing)
    // For now, if no content is found, we just let it sit or show empty state.
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: ${error.toString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.refresh(courseDetailsProvider(widget.courseId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
