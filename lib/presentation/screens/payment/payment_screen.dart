import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/payu_checkout_flow.dart';
import '../../../core/services/payu_checkout_service.dart';
import '../../providers/course_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/refresh_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CheckoutScreen({super.key, required this.courseId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _paying = false;
  String? _phaseLabel;

  Future<void> _handleFreeEnrollment() async {
    try {
      final success = await ref
          .read(paymentControllerProvider.notifier)
          .freeEnroll(widget.courseId);

      if (success && mounted) {
        ref.refreshAfterEnrollment();
        ref.refreshCourseDetails(widget.courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment Successful!')),
        );
        context.go(RouteConstants.enrollmentPath(widget.courseId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment Failed: $e')),
        );
      }
    }
  }

  Future<void> _startPayment(double amount) async {
    try {
      if (amount <= 0) {
        await _handleFreeEnrollment();
        return;
      }

      setState(() {
        _paying = true;
        _phaseLabel = 'Creating payment…';
      });

      final controller = ref.read(paymentControllerProvider.notifier);
      final params = await controller.createOrder(widget.courseId);

      await PayuCheckoutFlow.run(
        params: params,
        generateHashFn: ({
          required String txnid,
          required String hashName,
          String? hashString,
          String? hashType,
          String? postSalt,
        }) =>
            controller.generatePayuHash(
              txnid: txnid,
              hashName: hashName,
              hashString: hashString,
              hashType: hashType,
              postSalt: postSalt,
            ),
        waitForFulfillment: controller.waitForPayuFulfillment,
        onPhase: (phase) {
          if (!mounted) return;
          setState(() {
            _phaseLabel = switch (phase) {
              PayuCheckoutPhase.waitingForPayu => 'Waiting for PayU…',
              PayuCheckoutPhase.confirming => 'Confirming payment…',
            };
          });
        },
      );

      if (!mounted) return;
      ref.refreshAfterEnrollment();
      ref.refreshCourseDetails(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! Enrolling...')),
      );
      context.go(RouteConstants.enrollmentPath(widget.courseId));
    } on PayuCheckoutCancelledException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _paying = false;
          _phaseLabel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));
    final paymentState = ref.watch(paymentControllerProvider);

    final course = courseAsync.value;
    final activePlan = course?.activePaymentPlan;
    final displayPrice = activePlan?.amount ?? course?.price ?? 0.0;
    final busy = _paying || paymentState.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complete Purchase'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: courseAsync.when(
        data: (course) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          if (activePlan != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                activePlan.stageName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Lifetime Access',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₹${displayPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.security, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Safe & Secure Payment via PayU',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (_phaseLabel != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _phaseLabel!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: courseAsync.hasValue
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ElevatedButton(
                onPressed: busy ? null : () => _startPayment(displayPrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        displayPrice <= 0 ? 'Enroll Now' : 'Pay with PayU',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            )
          : null,
    );
  }
}
