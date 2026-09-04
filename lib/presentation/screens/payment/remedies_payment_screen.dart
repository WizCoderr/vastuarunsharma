import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../data/models/response/upi_payment_response.dart';
import '../../providers/payment_provider.dart';
import '../../providers/refresh_provider.dart';
import 'upi_payment_screen.dart';

class RemediesPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RemediesPaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<RemediesPaymentScreen> createState() =>
      _RemediesPaymentScreenState();
}

class _RemediesPaymentScreenState extends ConsumerState<RemediesPaymentScreen> {
  UpiPaymentResponse? _payment;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPayment());
  }

  Future<void> _initPayment() async {
    try {
      final payment = await ref
          .read(paymentControllerProvider.notifier)
          .createRemediesUpiPayment(widget.orderId);
      if (mounted) setState(() => _payment = payment);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_payment == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return UpiPaymentScreen(
      payment: _payment!,
      onPollStatus: (txnId) => ref
          .read(paymentControllerProvider.notifier)
          .getPaymentStatus(txnId),
      onVerify: (txnId) => ref
          .read(paymentControllerProvider.notifier)
          .verifyUpiPayment(txnId),
      onSuccess: () {
        ref.refreshOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!')),
        );
        context.go(RouteConstants.ordersPath);
      },
      onFailure: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please retry.')),
        );
        context.go(RouteConstants.ordersPath);
      },
    );
  }
}
