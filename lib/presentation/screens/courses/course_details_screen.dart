import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailsProvider(courseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => {
            if (Navigator.of(context).canPop())
              {context.pop()}
            else
              {context.go(RouteConstants.courses)},
          },
        ),
        centerTitle: true,
        title: const Text(
          "COURSE DETAILS",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
      body: courseAsync.when(
        data: (course) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Banner
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: course.thumbnail.isNotEmpty
                    ? Image.network(
                        course.thumbnail,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
              // Course Title
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              // Instructor Info
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage(
                      'assets/images/instructor.png',
                    )
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "INSTRUCTOR",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        course.instructorId == "6951a43ae20339f19833f2b1"
                            ? "Arun Sharma"
                            : "Vastu Expert",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const Text(
                    " 4.8 ",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Text("(120)", style: TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 22),

              // Course Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoTile(
                    Icons.access_time,
                    "${course.sections.fold<int>(0, (sum, s) => sum + s.lectures.length)} hrs",
                    "Duration",
                    context,
                  ),
                  _infoTile(
                    Icons.menu_book_rounded,
                    "${course.sections.length} Modules",
                    "Lessons",
                    context,
                  ),
                  _infoTile(
                    Icons.verified,
                    course.enrolled == true ? "Enrolled" : "Available",
                    "Status",
                    context,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About Course
              const Text(
                "About this Course",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                course.description,
                style: const TextStyle(height: 1.45, color: Colors.black87),
              ),
              const SizedBox(height: 28),

              // Curriculum Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Curriculum",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "${course.sections.length} Sections",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Curriculum List
              ...course.sections.map(
                (section) => _sectionTile(section, context),
              ),

              // Resources Section
              if (course.resources.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  "Resources",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ...course.resources.map((resource) => _resourceTile(resource)),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
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
                onPressed: () => ref.refresh(courseDetailsProvider(courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: courseAsync.when(
        data: (course) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "COURSE FEE",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    course.price == 0
                        ? "Free"
                        : "₹${course.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 50,
                width: 170,
                child: ElevatedButton(
                  onPressed: () {
                    final authState = ref.read(authStateProvider);
                    if (authState.value == null) {
                      _showLoginDialog(context);
                      return;
                    }

                    if (course.enrolled == true) {
                      context.go(RouteConstants.videoPlayerPath(courseId));
                    } else {
                      context.go(RouteConstants.paymentPath(courseId));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    course.enrolled == true ? 'Start Learning' : 'Join Now',
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(section, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...section.lectures
              .map(
                (lecture) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lecture.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _resourceTile(resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: resource.type == 'FREE'
                  ? Colors.blue.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.description,
              color: resource.type == 'FREE' ? Colors.blue : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  resource.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: resource.type == 'FREE'
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.download, color: Colors.grey),
        ],
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
}
