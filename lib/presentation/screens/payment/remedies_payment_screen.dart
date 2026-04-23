import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/refresh_provider.dart';

class RemediesPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RemediesPaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<RemediesPaymentScreen> createState() =>
      _RemediesPaymentScreenState();
}

class _RemediesPaymentScreenState extends ConsumerState<RemediesPaymentScreen> {
  late Razorpay _razorpay;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPayment());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
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
          .verifyRemediesPayment(
            razorpayOrderId: finalOrderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
            orderId: widget.orderId,
          );

      if (success && mounted) {
        ref.refreshOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful!")),
        );
        context.go(RouteConstants.ordersPath);
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

  Future<void> _startPayment() async {
    try {
      final orderData = await ref
          .read(paymentControllerProvider.notifier)
          .createRemediesOrder(widget.orderId);

      if (orderData != null) {
        _currentOrderId = orderData['id'];
        final user = ref.read(authStateProvider).value;
        var options = {
          'key': orderData['key'],
          'amount': orderData['amount'],
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
