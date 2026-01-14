import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/live_class_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/live_class.dart';
import '../../../domain/entities/course.dart';
import 'package:url_launcher/url_launcher.dart';

// Color Constants from Design
class DashboardColors {
  static const Color background = Color(0xFFFAFAFA); // Off-white background
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color accentGold = Color(0xFFE6B800); // Muted Gold/Mustard
  static const Color accentGoldLight = Color(0xFFFFF9E6);
  static const Color accentGreen = Color(0xFF34A853);
  static const Color accentGreenLight = Color(0xFFE8F5E9);
  static const Color buttonText = Colors.white;
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-reload data every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final user = ref.read(authStateProvider).value;
    await Future.wait([
      ref.refresh(allCoursesProvider.future),
      ref.refresh(enrolledCoursesProvider.future),
      if (user != null) ref.refresh(todayLiveClassesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

    // Calculate active count
    final activeCount = enrolledCoursesAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vastu Arun Sharma',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (user != null) ...[
                  // Listen to live classes changes to schedule notifications
                  Consumer(
                    builder: (context, ref, child) {
                      ref.listen(todayLiveClassesProvider, (previous, next) {
                        if (next.hasValue && next.value != null) {
                          ref
                              .read(notificationServiceProvider)
                              .scheduleClassNotifications(next.value!);
                        }
                      });
                      return const SizedBox.shrink();
                    },
                  ),

                  // Today's Live Class Banner
                  Consumer(
                    builder: (context, ref, child) {
                      final todayLiveClassesAsync = ref.watch(
                        todayLiveClassesProvider,
                      );
                      return todayLiveClassesAsync.when(
                        data: (classes) {
                          if (classes.isEmpty) return const SizedBox.shrink();
                          final liveClass = classes.first;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _LiveClassBanner(liveClass: liveClass),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, _) => const SizedBox.shrink(),
                      );
                    },
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Welcome back,\n'),
                        TextSpan(
                          text: '${user.name.split(" ").first}.',
                          style: const TextStyle(
                            color: Color(0xFFDCA000),
                          ), // Gold color for name
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's focus on your goals today.",
                    style: TextStyle(
                      fontSize: 16,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  // Guest Greeting
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Welcome,\n'),
                        TextSpan(
                          text: 'Guest.',
                          style: TextStyle(color: Color(0xFFDCA000)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to start learning.",
                    style: TextStyle(
                      fontSize: 16,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push(RouteConstants.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardColors.accentGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Login / Register"),
                  ),
                ],

                const SizedBox(height: 32),

                // Enrolled Courses Header
                if (user != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enrolled Courses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardColors.accentGoldLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount Active',
                          style: const TextStyle(
                            color: Color(0xFFB38F00), // Darker gold for text
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Courses List
                  enrolledCoursesAsync.when(
                    data: (courses) {
                      if (courses.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "You haven't enrolled in any courses yet.",
                                  style: TextStyle(
                                    color: DashboardColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push(RouteConstants.courses),
                                  child: const Text("Explore Courses"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _CourseProgressCard(course: course);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseProgressCard extends ConsumerWidget {
  final Course course;

  const _CourseProgressCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(courseCurriculumProvider(course.id));
    final progress = curriculumAsync.asData?.value.progress ?? 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price or Type Tag (Real Data)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DashboardColors.accentGoldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  course.price == 0 ? "FREE" : "PAID",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB38F00),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Thumbnail (Real Data)
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.background,
                  border: Border.all(color: Colors.grey[100]!),
                  image: course.thumbnail.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(course.thumbnail),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: course.thumbnail.isEmpty
                    ? const Icon(Icons.image, size: 20, color: Colors.grey)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // Instructor Name (Real Data) or Description snippet
          Text(
            course.description.isNotEmpty
                ? course.description
                : "Start Learning",
            style: TextStyle(
              fontSize: 14,
              color: DashboardColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progress",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                ),
              ),
              Text(
                "$percent%",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDCA000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: const Color(0xFFDCA000),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push(RouteConstants.courseDetailsPath(course.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCA000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  SizedBox(width: 4),
                  Text(
                    "Continue Learning",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClassBanner extends StatelessWidget {
  final LiveClass liveClass;

  const _LiveClassBanner({required this.liveClass});

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.status == 'LIVE';

    return GestureDetector(
      onTap: () {
        context.push(RouteConstants.courseDetailsPath(liveClass.courseId));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? "LIVE NOW" : "TODAY",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (liveClass.startsIn > 0 && !isLive)
                  Text(
                    "Starts in ${liveClass.startsIn} min",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              liveClass.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              liveClass.courseName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: liveClass.canJoin && liveClass.meetingUrl != null
                    ? () {
                        final uri = Uri.parse(liveClass.meetingUrl!);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white38,
                ),
                child: Text(
                  isLive
                      ? "Join Class"
                      : "Scheduled @ ${_formatTime(liveClass.scheduledAt)}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}
