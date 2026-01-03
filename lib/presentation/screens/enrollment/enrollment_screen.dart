import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/course_provider.dart';
import '../../providers/refresh_provider.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  final String courseId;

  const EnrollmentScreen({super.key, required this.courseId});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure enrolled courses are refreshed when reaching this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refreshAfterEnrollment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: courseAsync.when(
        data: (course) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Success icon
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "You're In!",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  "Enrollment Successful. You now have\nlifetime access to this material.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 35),

                // Course Card with Network Image from thumbnail
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (course.thumbnail.isNotEmpty)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.35,
                            child: Image.network(
                              course.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 100),
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_open_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Lifetime Access Unlocked",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pushNamed(
                      RouteConstants.videoPlayer,
                      pathParameters: {'courseId': widget.courseId},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Start Learning Now",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                GestureDetector(
                  onTap: () => context.go(RouteConstants.dashboard),
                  child: const Text(
                    "Return to Home",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(courseDetailsProvider(widget.courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
