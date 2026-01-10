import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/live_class.dart';

import '../../providers/course_provider.dart';
import '../../providers/live_class_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final allCoursesAsync = ref.watch(allCoursesProvider);
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

    final todayLiveClassesAsync = user != null
        ? ref.watch(todayLiveClassesProvider)
        : const AsyncValue.data(<LiveClass>[]);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          user != null
              ? 'Welcome back, ${user.name.split(" ").first}!'
              : 'Welcome to Vastu Learning',
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all providers
          await Future.wait([
            ref.refresh(allCoursesProvider.future),
            ref.refresh(enrolledCoursesProvider.future),
            if (user != null) ref.refresh(todayLiveClassesProvider.future),
          ]);
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Today's Live Class Banner
              if (user != null)
                todayLiveClassesAsync.when(
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
                ),
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.school,
                      title: 'All Courses',
                      onTap: () => context.push(RouteConstants.courses),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.book,
                      title: user != null ? 'My Courses' : 'Browse',
                      onTap: () => context.push(
                        user != null
                            ? RouteConstants.myCourses
                            : RouteConstants.courses,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Login prompt for guests
              if (user == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join Vastu Learning',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to track your progress and access enrolled courses',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => context.push(RouteConstants.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () =>
                                context.push(RouteConstants.register),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // My Courses Section (if logged in)
              if (user != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Continue Learning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteConstants.myCourses),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                enrolledCoursesAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No enrolled courses yet',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.take(5).length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _CourseCard(
                            course: course,
                            onTap: () => context.push(
                              RouteConstants.courseDetailsPath(course.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],

              // All Courses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explore Courses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push(RouteConstants.courses),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              allCoursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Center(child: Text('No courses available'));
                  }
                  return SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: courses.take(5).length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _CourseCard(
                          course: course,
                          onTap: () => context.push(
                            RouteConstants.courseDetailsPath(course.id),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error: ${error.toString()}')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final dynamic course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: course.thumbnail.isNotEmpty
                  ? Image.network(
                      course.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${course.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam, 
                        color: Colors.white, 
                        size: 16
                      ),
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
                  )
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
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
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
                    : null, // If null, the click passes through? No, disabled button blocks.
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white38,
                ),
                child: Text(isLive ? "Join Class" : "Scheduled @ ${_formatTime(liveClass.scheduledAt)}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}
