import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../providers/course_provider.dart';
import '../../../../domain/entities/course.dart';
import '../DashboardColors.dart';

class CourseProgressCard extends ConsumerWidget {
  final Course course;

  const CourseProgressCard({super.key, required this.course});

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
