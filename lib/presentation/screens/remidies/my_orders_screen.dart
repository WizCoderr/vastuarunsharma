import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vastuarunsharma/core/constants/route_constants.dart';
import 'package:vastuarunsharma/data/models/remidies/order.dart';
import 'package:vastuarunsharma/data/models/remidies/payment.dart';
import 'package:vastuarunsharma/domain/providers/remidies/order_providers.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Error loading orders: $error')),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final truncatedId =
        order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$truncatedId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    order.createdAt.toString().split(' ')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  _StatusBadge(status: order.status),
                  IconButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              if (order.payment != null) ...[
                const SizedBox(width: 8),
                _PaymentStatusBadge(status: order.payment!.status),
              ],
            ],
          ),
          if (_expanded) ...[
            const Divider(height: 16),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (order.status == OrderStatus.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(RouteConstants.remediesPaymentPath, extra: order.id);
                },
                child: const Text('Retry Payment'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color text;
    switch (status) {
      case PaymentStatus.success:
        bg = Colors.green[100]!;
        text = Colors.green[900]!;
        break;
      case PaymentStatus.failed:
        bg = Colors.red[100]!;
        text = Colors.red[900]!;
        break;
      case PaymentStatus.refunded:
        bg = Colors.purple[100]!;
        text = Colors.purple[900]!;
        break;
      case PaymentStatus.pending:
        bg = Colors.orange[100]!;
        text = Colors.orange[900]!;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bgColor;
    late Color textColor;

    switch (status) {
      case OrderStatus.pending:
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        break;
      case OrderStatus.processing:
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case OrderStatus.shipped:
        bgColor = Colors.purple[100]!;
        textColor = Colors.purple[900]!;
        break;
      case OrderStatus.delivered:
        bgColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
