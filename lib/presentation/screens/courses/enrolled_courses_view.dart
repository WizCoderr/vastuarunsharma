import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import 'widgets/course_card.dart';

class EnrolledCoursesView extends ConsumerWidget {
  const EnrolledCoursesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;

    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Please login to view enrolled courses',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.landing),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(enrolledCoursesProvider.future),
      child: enrolledCoursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(
              child: Text(
                "No enrolled courses available",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              // Since this is the enrolled courses view, we can assume isEnrolled is true
              // or use the property if preferred, but logically they are enrolled.
              final isEnrolled = course.enrolled ?? true;

              return CourseCard(
                course: course,
                isEnrolled: isEnrolled,
                onCardTap: () =>
                    context.push(RouteConstants.courseDetailsPath(course.id)),
                onActionTap: () {
                  context.pushNamed(
                    RouteConstants.videoPlayer,
                    pathParameters: {'courseId': course.id},
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(enrolledCoursesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
