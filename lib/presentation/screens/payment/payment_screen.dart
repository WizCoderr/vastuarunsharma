import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
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
  late Razorpay _razorpay;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Prefer razorpay's returned orderId if present; fall back to our stored order id
    final razorpayOrderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    debugPrint(
      'PaymentSuccessResponse: orderId=$razorpayOrderId, paymentId=$paymentId, signature=$signature',
    );
    debugPrint('Stored order id: $_currentOrderId');

    final finalOrderId = razorpayOrderId ?? _currentOrderId;

    if (finalOrderId == null || paymentId == null || signature == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification Failed: Missing payment details from gateway',
            ),
          ),
        );
      }
      return;
    }
    try {
      final success = await ref
          .read(paymentControllerProvider.notifier)
          .verifyPayment(
            razorpayOrderId: finalOrderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
            courseId: widget.courseId,
          );

      if (success != null && mounted) {
        // Refresh course providers to update enrollment status
        ref.refreshAfterEnrollment();
        ref.refreshCourseDetails(widget.courseId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful! Enrolling...")),
        );
        // Navigate to Enrollment/Success Screen
        context.go(RouteConstants.enrollmentPath(widget.courseId));
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      if (mounted) {
        final message = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: $message")),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  Future<void> _startPayment(double amount) async {
    try {
      // Check for free course
      if (amount <= 0) {
        await _handleFreeEnrollment();
        return;
      }

      final orderData = await ref
          .read(paymentControllerProvider.notifier)
          .createOrder(widget.courseId);

      if (orderData != null) {
        _currentOrderId = orderData['id'];

        // Heuristic: If backend returns amount in Rupees (e.g. 500) instead of Paise (50000),
        // we correct it here. Expected Paise is roughly amount * 100.
        // If the returned value is close to 'amount' (Rupees) vs 'amount * 100' (Paise),
        // we multiply by 100.
        var paymentAmount = orderData['amount'];
        if (paymentAmount is num && paymentAmount < (amount * 50)) {
          paymentAmount = (paymentAmount * 100).round();
        }

        final user = ref.read(authStateProvider).value;
        var options = {
          'key': orderData['key'],
          'amount': paymentAmount,
          'name': 'Vastu Arun Sharma',
          'description': orderData['description'],
          'order_id': orderData['id'],
          'timeout': 120,
          'prefill': {
            'contact': user?.mobileNumber ?? '',
            'email': user?.email ?? '',
          },
        };
        _razorpay.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to initiate payment: $e")));
    }
  }

  Future<void> _handleFreeEnrollment() async {
    try {
      final success = await ref
          .read(paymentControllerProvider.notifier)
          .freeEnroll(widget.courseId);

      if (success && mounted) {
        ref.refreshAfterEnrollment();
        ref.refreshCourseDetails(widget.courseId);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Enrollment Successful!")));
        context.go(RouteConstants.enrollmentPath(widget.courseId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Enrollment Failed: $e")));
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

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent bg
      appBar: AppBar(
        title: const Text("Complete Purchase"),
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
                "Order Summary",
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
                      color: Colors.black.withOpacity(.05),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            "Lifetime Access",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "₹${displayPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: course.thumbnail.isNotEmpty
                          ? Image.network(
                              course.thumbnail,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
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
                  "Safe & Secure Payment via Razorpay",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      bottomNavigationBar: courseAsync.hasValue
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ElevatedButton(
                onPressed: paymentState.isLoading
                    ? null
                    : () {
                        _startPayment(displayPrice);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: paymentState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        displayPrice <= 0 ? "Enroll Now" : "Pay Now",
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
