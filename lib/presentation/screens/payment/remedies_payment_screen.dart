import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/payu_checkout_flow.dart';
import '../../../core/services/payu_checkout_service.dart';
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
  String? _error;
  bool _loading = true;
  bool _paying = false;
  String _statusLabel = 'Creating payment…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCheckout());
  }

  Future<void> _startCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
      _paying = true;
      _statusLabel = 'Creating payment…';
    });

    try {
      final controller = ref.read(paymentControllerProvider.notifier);
      final params = await controller.createRemediesPayuOrder(widget.orderId);

      if (mounted) {
        setState(() {
          _loading = false;
          _statusLabel = 'Waiting for PayU…';
        });
      }

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
            _statusLabel = switch (phase) {
              PayuCheckoutPhase.waitingForPayu => 'Waiting for PayU…',
              PayuCheckoutPhase.confirming => 'Confirming payment…',
            };
          });
        },
      );

      if (!mounted) return;
      ref.refreshOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );
      context.go(RouteConstants.ordersPath);
    } on PayuCheckoutCancelledException {
      if (!mounted) return;
      setState(() {
        _error = 'Payment cancelled';
        _loading = false;
        _paying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _paying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _paying ? null : _startCheckout,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _statusLabel,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
