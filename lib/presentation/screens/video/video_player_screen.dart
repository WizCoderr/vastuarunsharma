import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/live_class.dart';
import '../../providers/course_provider.dart';
import '../../providers/live_class_provider.dart';
import '../../providers/video_player_provider.dart';
import '../../providers/progress_provider.dart';
import '../../../data/models/request/progress_update_request.dart';
import '../../../domain/entities/recording.dart';
import 'live_session_redirect_screen.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String? initialLectureId;
  final String? initialRecordingId;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    this.initialLectureId,
    this.initialRecordingId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  Lecture? _currentLecture;
  int _currentSectionIndex = 0;
  int _currentLectureIndex = -1; // -1 means it could be a recording
  int _currentRecordingIndex = -1;
  LiveClass? _availableLiveClass;
  bool _isLoadingContent = false;
  List<Recording> _courseRecordings = [];

  // Store reference to avoid using ref in dispose()
  late final VideoPlayerNotifier _videoPlayerNotifier;

  @override
  void initState() {
    super.initState();
    _videoPlayerNotifier = ref.read(videoPlayerProvider.notifier);
  }

  @override
  void dispose() {
    // Ensure orientation is reset when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoPlayerNotifier.disposePlayer();
    super.dispose();
  }

  Future<void> _loadLecture(Lecture lecture) async {
    setState(() {
      _currentLecture = lecture;
      _isLoadingContent = true;
      _availableLiveClass = null; // Reset live class
    });

    String videoUrl = lecture.videoUrl;

    if (videoUrl.isEmpty) {
      debugPrint(
        'No video URL found for lecture ${lecture.id}. Checking for live classes...',
      );
      try {
        // Fetch today's and upcoming live classes
        final todayClasses = await ref.read(todayLiveClassesProvider.future);
        final upcomingClasses = await ref.read(
          upcomingLiveClassesProvider.future,
        );

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
          _videoPlayerNotifier.stop();
          return;
        }
      } catch (e) {
        debugPrint('Error fetching live classes: $e');
      }
    }

    // Initialize player with whatever URL we found (or empty)
    _videoPlayerNotifier.initialize(videoUrl, lecture);

    // Listen for completion handled via provider state listener in build method

    setState(() {
      _isLoadingContent = false;
    });
  }

  void _playRecording(Recording recording, int index) {
    setState(() {
      _currentRecordingIndex = index;
      _currentSectionIndex = -1;
      _currentLectureIndex = -1;
    });

    // Map recording to a lecture-like structure for the player
    final lecture = Lecture(
      id: recording.id,
      title: recording.title,
      videoUrl: recording.videoUrl,
      videoProvider:
          'YouTube', // Recordings are usually YouTube links in this app
    );

    _loadLecture(lecture);
  }

  void _playLecture(Course course, int sectionIndex, int lectureIndex) {
    final section = course.sections[sectionIndex];
    final lecture = section.lectures[lectureIndex];

    setState(() {
      _currentSectionIndex = sectionIndex;
      _currentLectureIndex = lectureIndex;
      _currentRecordingIndex = -1;
    });

    _loadLecture(lecture);
  }

  bool _canPlayPrevious(Course course) {
    if (_currentRecordingIndex != -1) {
      return _currentRecordingIndex > 0;
    }
    if (_currentLectureIndex > 0) return true;
    for (int i = _currentSectionIndex - 1; i >= 0; i--) {
      if (course.sections[i].lectures.isNotEmpty) return true;
    }
    return false;
  }

  bool _canPlayNext(Course course) {
    if (_currentRecordingIndex != -1) {
      return _currentRecordingIndex < _courseRecordings.length - 1;
    }
    final currentSection = course.sections[_currentSectionIndex];
    if (_currentLectureIndex < currentSection.lectures.length - 1) return true;
    for (int i = _currentSectionIndex + 1; i < course.sections.length; i++) {
      if (course.sections[i].lectures.isNotEmpty) return true;
    }
    return false;
  }

  void _playNextLecture(Course course) {
    if (_currentRecordingIndex != -1) {
      if (_currentRecordingIndex < _courseRecordings.length - 1) {
        _playRecording(
          _courseRecordings[_currentRecordingIndex + 1],
          _currentRecordingIndex + 1,
        );
      }
      return;
    }

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
    if (_currentRecordingIndex != -1) {
      if (_currentRecordingIndex > 0) {
        _playRecording(
          _courseRecordings[_currentRecordingIndex - 1],
          _currentRecordingIndex - 1,
        );
      }
      return;
    }

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

  Future<void> _onVideoEnded() async {
    // Called when video ends
    if (_currentLecture != null) {
      final req = ProgressUpdateRequest(
        lectureId: _currentLecture!.id,
        courseId: widget.courseId,
        status: 'COMPLETED',
        watchedDuration:
            0, // Duration tracking tricky with iframe without proper metadata stream mapping
      );
      _saveProgress(req);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));

    // Iframe player handles fullscreen overlay internally or differently.
    // We just return Scaffold.

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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_currentRecordingIndex != -1)
                Text(
                  'Recording ${_currentRecordingIndex + 1} of ${_courseRecordings.length}',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                )
              else
                Text(
                  'Lecture ${_getCurrentLectureNumber(course)} of ${_getTotalLectures(course)}',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
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
    // ... rest of content logic ...

    if (course.sections.isEmpty && _courseRecordings.isEmpty) {
      // Check for recordings if not already loaded
      ref.listen(courseRecordingsProvider(widget.courseId), (previous, next) {
        if (next.hasValue) {
          setState(() {
            _courseRecordings = next.value!;
          });
        }
      });

      // Still empty after potential listen setup?
      // (Actually we should probably use recordingsAsync here)
    }

    // Use a separate async watch for recordings
    final recordingsAsync = ref.watch(
      courseRecordingsProvider(widget.courseId),
    );

    if (_currentLecture == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialRecordingId != null && recordingsAsync.hasValue) {
          _findAndPlayRecording(
            recordingsAsync.value!,
            widget.initialRecordingId!,
          );
        } else if (widget.initialLectureId != null) {
          _findAndPlayLecture(course, widget.initialLectureId!);
        } else {
          _playFirstAvailableLecture(course);
        }
      });
    }

    final playerState = ref.watch(videoPlayerProvider);
    final controller = playerState?.controller;

    // Listen for completion
    ref.listen(videoPlayerProvider, (previous, next) {
      if (next?.isCompleted == true && previous?.isCompleted != true) {
        _onVideoEnded();
      }
    });

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
              : (playerState?.errorMessage != null)
              ? Center(
                  child: Text(
                    playerState!.errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : (controller != null)
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    SizedBox.expand(
                      child: YoutubePlayer(
                        key: ValueKey(controller.hashCode),
                        controller: controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                    // Overlay to hide YouTube's copy link icon (bottom-left)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 72,
                        height: 72,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
        ),

        // Course Info Header
        _buildCourseInfoHeader(course),

        // Navigation
        _buildNavigationControls(course),

        // Course Content List
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Lectures Sections
                ...course.sections.asMap().entries.map((entry) {
                  final sectionIndex = entry.key;
                  final section = entry.value;
                  return _buildSectionTile(course, sectionIndex, section);
                }),

                // Recordings Section
                recordingsAsync.when(
                  data: (recordings) {
                    if (recordings.isEmpty) return const SizedBox.shrink();
                    return _buildRecordingsSection(recordings);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingsSection(List<Recording> recordings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "Class Recordings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                "${recordings.length} Videos",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ...recordings.asMap().entries.map((entry) {
          final index = entry.key;
          final recording = entry.value;
          final isPlaying = _currentRecordingIndex == index;

          return _buildRecordingTile(recording, index, isPlaying);
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecordingTile(Recording recording, int index, bool isPlaying) {
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
        onTap: () => _playRecording(recording, index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isPlaying
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isPlaying ? AppColors.primary : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${recording.durationMinutes} mins",
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _findAndPlayRecording(List<Recording> recordings, String recordingId) {
    for (int i = 0; i < recordings.length; i++) {
      if (recordings[i].id == recordingId) {
        _playRecording(recordings[i], i);
        return;
      }
    }
  }

  Widget _buildCourseInfoHeader(Course course) {
    final bool isRecording = _currentRecordingIndex != -1;
    final totalLectures = _getTotalLectures(course);
    final currentLecture = _getCurrentLectureNumber(course);

    final totalItems = isRecording ? _courseRecordings.length : totalLectures;
    final currentItem = isRecording
        ? _currentRecordingIndex + 1
        : currentLecture;
    final progress = totalItems > 0 ? currentItem / totalItems : 0.0;
    final label = isRecording ? 'Recording' : 'Lecture';

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
                      '$label $currentItem of $totalItems',
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
            isRecording
                ? '${_courseRecordings.length} Recordings'
                : '${course.sections.length} Sections',
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
    for (int i = 0; i < course.sections.length; i++) {
      if (course.sections[i].lectures.isNotEmpty) {
        _playLecture(course, i, 0);
        return;
      }
    }

    // Live class fallback logic
    final allLiveClasses = [
      ...course.liveClasses,
      ...course.sections.expand((s) => s.liveClasses),
    ];

    if (allLiveClasses.isNotEmpty) {
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
  }

  Widget _buildError(Object error) {
    final errorStr = error.toString().toLowerCase();
    final isOverdue = errorStr.contains("payment overdue");
    final isExpired = errorStr.contains("course has expired");

    if (isOverdue) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 64, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                "Access Restricted",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please complete your pending fees to continue accessing course content.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push(
                  RouteConstants.paymentProgressPath(widget.courseId),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text("Go to Payments"),
              ),
              TextButton(
                onPressed: () => context.go(RouteConstants.myCourses),
                child: const Text(
                  "Back to My Courses",
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isExpired) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history_toggle_off,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                "Course Finished",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This course has reached its end date and is no longer available for playback.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(RouteConstants.courses),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text("Browse Other Courses"),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong. Please try again.',
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

  Future<void> _saveProgress(ProgressUpdateRequest req) async {
    await ref.read(progressRemoteDataSourceProvider).updateProgress(req);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress saved!')));
    }
  }
}
