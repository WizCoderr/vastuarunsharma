import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import 'enrolled_courses_view.dart';
import 'widgets/course_card.dart';

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

    final allCoursesAsync = ref.watch(allCoursesProvider);

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
              child: tabIndex == 1
                  ? const EnrolledCoursesView()
                  : allCoursesAsync.when(
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

                            return CourseCard(
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
                                allCoursesProvider,
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
