import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../providers/course_provider.dart';
import '../../../../domain/entities/course.dart';
import '../DashboardColors.dart';
import '../../../widgets/glass_container.dart';

class CourseProgressCard extends ConsumerWidget {
  final Course course;

  const CourseProgressCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(courseCurriculumProvider(course.id));
    final progress = curriculumAsync.asData?.value.progress ?? 0.0;
    final percent = (progress * 100).toInt();

    return GlassContainer(
      padding: EdgeInsets.zero, // Remove default padding for full-width image
      borderRadius: 24, // Reduced radius for a card look, was 100 which is very round
      opacity: 0, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header Image
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DashboardColors.background,
                  image: course.thumbnail.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(course.thumbnail),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: course.thumbnail.isEmpty
                    ? const Center(child: Icon(Icons.image, size: 48, color: Colors.grey))
                    : null,
              ),
              // Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardColors.accentGoldLight.withOpacity(0.9),
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
              ),
            ],
          ),
          
          // Content Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 20, // Slightly smaller to fit better
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
                  style: const TextStyle(
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
                    backgroundColor: Colors.grey[200],
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Matching the modern look
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
          ),
        ],
      ),
    );
  }
}
