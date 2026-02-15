import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/live_class_provider.dart';
import '../../../core/services/notification_service.dart';
import 'DashboardColors.dart';
import 'components/InstructorCard.dart';
import 'components/ServiceCard.dart';
import 'components/CourseProgressCard.dart';
import 'components/LiveClassBanner.dart';
import 'components/TestimonialsSection.dart';
import 'components/InquiryCard.dart';
import 'components/TrustMarkersSection.dart';

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
    await Future.wait(<Future>[
      ref.refresh(allCoursesProvider.future),
      ref.refresh(enrolledCoursesProvider.future),
      if (user != null)
        ref.refresh(todayLiveClassesProvider.future)
      else
        Future.value(), // No live classes to refresh for guests
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'VASTU ARUN SHARMA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user != null) ...[
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
                            child: LiveClassBanner(liveClass: liveClass),
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
                        const TextSpan(text: 'Welcome,\n'),
                        TextSpan(
                          text: '${user.name.split(" ").first}.',
                          style: const TextStyle(
                            color: DashboardColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
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
                          style: TextStyle(color: DashboardColors.accentGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign in to start learning.",
                    style: TextStyle(
                      fontSize: 16,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push(RouteConstants.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardColors.accentGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Login / Register",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Enrolled Courses (Only if logged in)
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
                            color: Color(0xFFB38F00),
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
                                const Text(
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return CourseProgressCard(course: course);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                  const SizedBox(height: 32),
                ],

                // About Instructor
                const InstructorCard(),
                const SizedBox(height: 32),

                // Free Services
                const Text(
                  'Free Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      ServiceCard(
                        icon: Icons.menu_book_rounded,
                        title: 'Basic Vastu Audit',
                        description:
                            "Get a preliminary assessment of your property's energy flow and basic compliance check.",
                        actionText: 'Start Audit',
                        onTap: () {
                          // TODO: Navigate to Audit
                        },
                      ),
                      const SizedBox(width: 16),
                      ServiceCard(
                        icon: Icons.compass_calibration_rounded,
                        title: 'Direction Check',
                        description:
                            "Accurately determine cardinal directions using our digital compass tool.",
                        actionText: 'Open Tool',
                        onTap: () => context.push(RouteConstants.compass),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Paid Services
                const Text(
                  'Paid Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      ServiceCard(
                        icon: Icons.home_rounded,
                        title: 'Professional Home Consultation',
                        description:
                            "In-depth analysis of your home layout with personalized remedies and report.",
                        actionText: 'Book Now',
                        onTap: () {
                          // TODO: Navigate to Booking
                        },
                      ),
                      const SizedBox(width: 16),
                      ServiceCard(
                        icon: Icons.store_rounded,
                        title: 'Commercial Consultation',
                        description:
                            "Optimize your workspace for better business growth and employee productivity.",
                        actionText: 'Book Now',
                        onTap: () {
                          // TODO: Navigate to Booking
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Testimonials
                const TestimonialsSection(),
                const SizedBox(height: 32),

                // Inquiry Form
                const InquiryCard(),
                const SizedBox(height: 32),

                // Trust Markers
                const TrustMarkersSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
