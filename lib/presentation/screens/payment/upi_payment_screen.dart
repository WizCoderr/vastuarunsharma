import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/response/upi_payment_response.dart';

class UpiPaymentScreen extends StatefulWidget {
  final UpiPaymentResponse payment;
  final Future<PaymentStatusResponse> Function(String transactionId) onPollStatus;
  final Future<void> Function(String transactionId) onVerify;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const UpiPaymentScreen({
    super.key,
    required this.payment,
    required this.onPollStatus,
    required this.onVerify,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  Timer? _pollTimer;
  String _status = 'PENDING';
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final result = await widget.onPollStatus(widget.payment.transactionId);
        if (!mounted) return;
        setState(() => _status = result.status);

        if (result.status == 'COMPLETED' || result.status == 'PAID') {
          _pollTimer?.cancel();
          widget.onSuccess();
        } else if (result.status == 'FAILED') {
          _pollTimer?.cancel();
          widget.onFailure();
        }
      } catch (_) {}
    });
  }

  Future<void> _launchUpi(String? url) async {
    final target = url ?? widget.payment.upiUrl;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _manualVerify() async {
    setState(() => _verifying = true);
    try {
      await widget.onVerify(widget.payment.transactionId);
      final result = await widget.onPollStatus(widget.payment.transactionId);
      if (!mounted) return;
      if (result.status == 'COMPLETED' || result.status == 'PAID') {
        widget.onSuccess();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrBytes = widget.payment.qrCode.isNotEmpty
        ? base64Decode(widget.payment.qrCode)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Pay via UPI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (qrBytes != null)
              Center(
                child: Image.memory(
                  qrBytes,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Transaction: ${widget.payment.transactionId}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (widget.payment.amount != null) ...[
              const SizedBox(height: 8),
              Text(
                '₹${widget.payment.amount!.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
              ),
            ],
            const SizedBox(height: 24),
            _UpiButton(
              label: 'Google Pay',
              onTap: () => _launchUpi(widget.payment.deepLinks?['google_pay']),
            ),
            _UpiButton(
              label: 'PhonePe',
              onTap: () => _launchUpi(widget.payment.deepLinks?['phonepe']),
            ),
            _UpiButton(
              label: 'Paytm',
              onTap: () => _launchUpi(widget.payment.deepLinks?['paytm']),
            ),
            _UpiButton(
              label: 'BHIM UPI',
              onTap: () => _launchUpi(widget.payment.deepLinks?['bhim']),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifying ? null : _manualVerify,
              child: Text(_verifying ? 'Verifying…' : "I've completed payment"),
            ),
            const SizedBox(height: 12),
            Text(
              'Status: $_status',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _UpiButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label),
      ),
    );
  }
}
