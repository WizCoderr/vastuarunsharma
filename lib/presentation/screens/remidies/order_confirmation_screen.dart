import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String estimatedDelivery;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.estimatedDelivery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              child: Icon(Icons.check, size: 48, color: Colors.green.shade700),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed Successfully!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated delivery by $estimatedDelivery',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Continue Shopping'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Navigate to orders history
              },
              child: const Text('View Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
