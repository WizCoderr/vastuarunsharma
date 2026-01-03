import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../domain/entities/course.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  int tabIndex = 0; // 0 = All Courses | 1 = Enrolled

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on tab
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;

    final coursesAsync = tabIndex == 0
        ? ref.watch(allCoursesProvider)
        : (isLoggedIn
              ? ref.watch(enrolledCoursesProvider)
              : const AsyncValue.data([]));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Courses"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Tabs
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200],
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _tabButton("All Courses", 0),
                  _tabButton("Enrolled", 1),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (tabIndex == 1 && !isLoggedIn)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Please login to view enrolled courses',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go(RouteConstants.landing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    )
                  : coursesAsync.when(
                      data: (courses) {
                        if (courses.isEmpty) {
                          return const Center(
                            child: Text(
                              "No courses available",
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            final isEnrolled = course.enrolled ?? false;

                            return _CourseCard(
                              course: course,
                              isEnrolled: isEnrolled,
                              onCardTap: () => context.push(
                                RouteConstants.courseDetailsPath(course.id),
                              ),
                              onActionTap: () {
                                if (!isLoggedIn) {
                                  _showLoginDialog(context);
                                  return;
                                }
                                if (isEnrolled) {
                                  context.pushNamed(
                                    RouteConstants.videoPlayer,
                                    pathParameters: {'courseId': course.id},
                                  );
                                } else {
                                  context.push(
                                    RouteConstants.paymentPath(course.id),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${error.toString()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(
                                tabIndex == 0
                                    ? allCoursesProvider
                                    : enrolledCoursesProvider,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (tabIndex == 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    "More courses coming soon.",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("To buy this course, you need to login first."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.push(RouteConstants.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final selected = tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isEnrolled;
  final VoidCallback onCardTap;
  final VoidCallback onActionTap;

  const _CourseCard({
    required this.course,
    required this.isEnrolled,
    required this.onCardTap,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: course.thumbnail.isNotEmpty
                  ? Image.network(
                      course.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              course.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 5),
                Text(
                  "${course.sections.fold<int>(0, (sum, section) => sum + section.lectures.length)} Lessons",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  isEnrolled
                      ? "Continue Learning"
                      : "Enroll for ₹${course.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
