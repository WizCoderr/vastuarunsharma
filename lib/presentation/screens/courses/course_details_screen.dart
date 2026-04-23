import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/course_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/live_class_provider.dart';
import '../../../domain/entities/live_class.dart';
import '../../../domain/entities/recording.dart';
import '../../../domain/entities/course.dart';
import '../../providers/payment_provider.dart';
import '../../providers/refresh_provider.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_container.dart';
import '../../../data/models/response/student_payment_model.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailsProvider(courseId));
    final upcomingClassesAsync = ref.watch(upcomingLiveClassesProvider);
    final recordingsAsync = ref.watch(courseRecordingsProvider(courseId));
    final installmentsAsync = ref.watch(
      studentCoursePaymentsProvider(courseId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => {
            if (Navigator.of(context).canPop())
              {context.pop()}
            else
              {context.go(RouteConstants.courses)},
          },
        ),
        title: const Text(
          "COURSE DETAILS",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
      body: courseAsync.when(
        data: (course) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(courseDetailsProvider(courseId).future),
              ref.refresh(upcomingLiveClassesProvider.future),
              ref.refresh(courseRecordingsProvider(courseId).future),
              ref.refresh(studentCoursePaymentsProvider(courseId).future),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                // Identity Display (Post-Enrollment)
                if (course.isEnrolled && course.serialNumber != null)
                  _serialNumberCard(course.serialNumber!, context),

                // Active Offer Banner
                if (!course.isEnrolled && course.activePaymentPlan != null)
                  _activeOfferBanner(course.activePaymentPlan!, context),

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
                      ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      "(120)",
                      style: TextStyle(color: Colors.black54),
                    ),
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
                      course.isEnrolled ? "Enrolled" : "Available",
                      "Status",
                      context,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Tiers & Installments Section
                if (!course.isEnrolled && course.paymentPlans.isNotEmpty)
                  _paymentPlansSection(course.paymentPlans),

                // Upcoming Live Classes Section
                upcomingClassesAsync.when(
                  data: (classes) {
                    final courseClasses = classes
                        .where((c) => c.courseId == courseId)
                        .toList();
                    if (courseClasses.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upcoming Live Class",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...courseClasses.map(
                          (c) => _LiveClassTile(liveClass: c),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                // Installment Tracking Section
                if (course.isEnrolled)
                  installmentsAsync.when(
                    data: (payments) => _installmentsSection(payments),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                // Recordings Section
                recordingsAsync.when(
                  data: (recordings) {
                    if (recordings.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Class Recordings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recordings.map((r) => _RecordingTile(recording: r)),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                  ...course.resources.map(
                    (resource) =>
                        _resourceTile(context, resource, course.isEnrolled),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
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
                'Something went wrong. Please try again.',
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
        data: (course) {
          final isEnrolled = course.isEnrolled;
          final activePlan = course.activePaymentPlan;

          // Logic for Enrollment Button
          String buttonText = "Join Now";
          bool isEnabled = false;
          double? displayPrice;
          String? subText;

          if (isEnrolled) {
            buttonText = "Go to Curriculum";
            isEnabled = true;
          } else if (activePlan != null) {
            buttonText = "Join Now";
            isEnabled = true;
            displayPrice = activePlan.amount;
            subText = activePlan.stageName.toUpperCase();
          } else {
            // Check for future plans
            final now = DateTime.now();
            final futurePlans =
                course.paymentPlans
                    .where(
                      (p) => p.startDate != null && p.startDate!.isAfter(now),
                    )
                    .toList()
                  ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

            if (futurePlans.isNotEmpty) {
              buttonText = "Enrollment Closed";
              isEnabled = false;
              subText =
                  "NEXT BATCH: ${_formatDate(futurePlans.first.startDate!)}";
            } else {
              buttonText = "Enrollment Opening Soon";
              isEnabled = false;
            }
          }

          return GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 0, // Flat bottom sheet
            opacity: 0.9,
            child: Row(
              children: [
                if (!isEnrolled)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subText ?? "COURSE FEE",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      if (displayPrice != null)
                        Text(
                          displayPrice == 0
                              ? "Free"
                              : "₹${displayPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                if (isEnrolled)
                  const Text(
                    "Already Enrolled",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                const Spacer(),
                GlassButton(
                  width: 180,
                  height: 50,
                  onPressed: !isEnabled
                      ? null
                      : () async {
                          final authState = ref.read(authStateProvider);
                          if (authState.value == null) {
                            _showLoginDialog(context);
                            return;
                          }

                          if (isEnrolled) {
                            context.go(
                              RouteConstants.videoPlayerPath(courseId),
                            );
                          } else if (displayPrice == 0) {
                            // Free Course Bypass
                            try {
                              final success = await ref
                                  .read(paymentControllerProvider.notifier)
                                  .freeEnroll(courseId);

                              if (success && context.mounted) {
                                ref.refreshAfterEnrollment();
                                ref.refreshCourseDetails(courseId);
                                context.go(
                                  RouteConstants.enrollmentPath(courseId),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Enrollment Failed: $e"),
                                  ),
                                );
                              }
                            }
                          } else {
                            context.push(
                              RouteConstants.checkoutPath,
                              extra: courseId,
                            );
                          }
                        },
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

  Widget _sectionTile(Section section, BuildContext context) {
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
          ...section.lectures.map(
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
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
          ),
        ],
      ),
    );
  }

  Widget _resourceTile(BuildContext context, resource, bool isEnrolled) {
    bool isLocked = resource.type != 'FREE' && !isEnrolled;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Enroll in this course to access paid resources."),
            ),
          );
          return;
        }

        if (resource.url.isNotEmpty) {
          context.push(
            '/pdf-viewer',
            extra: {'url': resource.url, 'title': resource.title},
          );
        }
      },
      child: Container(
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
                color: isLocked
                    ? Colors.grey.shade100
                    : (resource.type == 'FREE'
                          ? Colors.blue.shade50
                          : Colors.orange.shade50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isLocked ? Icons.lock : Icons.description,
                color: isLocked
                    ? Colors.grey
                    : (resource.type == 'FREE' ? Colors.blue : Colors.orange),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isLocked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  Text(
                    isLocked ? "Locked" : resource.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLocked
                          ? Colors.grey
                          : (resource.type == 'FREE'
                                ? Colors.blue
                                : Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
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

  Widget _activeOfferBanner(PaymentPlan plan, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Limited Time Offer: ${plan.stageName}".toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (plan.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Ends on ${_formatDate(plan.endDate!)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentPlansSection(List<PaymentPlan> plans) {
    // Sort by orderIndex
    final sortedPlans = List<PaymentPlan>.from(plans)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          "Enrollment & Payment Plans",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...sortedPlans.map((plan) {
          final isPast =
              plan.endDate != null && plan.endDate!.isBefore(DateTime.now());
          final isWindow = plan.isWindow;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.shade50
                  : (isWindow ? Colors.blue.shade50 : Colors.orange.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPast
                    ? Colors.grey.shade200
                    : (isWindow
                          ? Colors.blue.shade100
                          : Colors.orange.shade100),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.stageName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (plan.startDate != null && plan.endDate != null)
                        Text(
                          "${_formatDate(plan.startDate!)} - ${_formatDate(plan.endDate!)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isPast ? Colors.grey : Colors.black54,
                          ),
                        )
                      else if (plan.dueAfterDays > 0)
                        Text(
                          "Due ${plan.dueAfterDays} days after enrollment",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                      else if (plan.dueAfterDays == 0 && !isWindow)
                        const Text(
                          "One-time Admission Fee",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      if (plan.description != null &&
                          plan.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            plan.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isPast ? Colors.grey : Colors.black45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "₹${plan.amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPast
                        ? Colors.grey
                        : (isWindow
                              ? Colors.blue.shade700
                              : Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _serialNumberCard(String serialNumber, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Registered Student ID".toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            serialNumber,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _installmentsSection(List<StudentPaymentModel> payments) {
    if (payments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Status",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...payments.map((p) {
          final isPaid = p.status == PaymentStatus.paid;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaid ? Colors.green.shade100 : Colors.blue.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPaid ? Icons.check_circle : Icons.schedule,
                  color: isPaid ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? Colors.green.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        isPaid
                            ? "Paid on ${_formatDate(p.dueDate)}"
                            : "Upcoming: ${_formatDate(p.dueDate)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isPaid
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${p.amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.green.shade900
                        : Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${localDt.day} ${months[localDt.month - 1]} ${localDt.year}";
  }
}

class _LiveClassTile extends StatelessWidget {
  final LiveClass liveClass;
  const _LiveClassTile({required this.liveClass});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  liveClass.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Scheduled: ${_formatTime(liveClass.scheduledAt)}",
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: liveClass.canJoin && liveClass.meetingUrl != null
                  ? () {
                      launchUrl(
                        Uri.parse(liveClass.meetingUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.red.shade100,
              ),
              child: const Text("Join Class"),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    return "${localDt.day}/${localDt.month} ${localDt.hour}:${localDt.minute.toString().padLeft(2, '0')}";
  }
}

class _RecordingTile extends StatelessWidget {
  final Recording recording;
  const _RecordingTile({required this.recording});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Open Video Player with specific recording ID
        context.push(RouteConstants.videoPlayerPath(
          recording.courseId,
          recordingId: recording.id,
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 30,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${recording.durationMinutes} mins • ${_formatDate(recording.date)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    return "${localDt.day}/${localDt.month}/${localDt.year}";
  }
}
