import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/response/student_payment_model.dart';

class PaymentPlanCard extends StatelessWidget {
  final String stageName;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;
  final VoidCallback? onPayNow;

  const PaymentPlanCard({
    super.key,
    required this.stageName,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status == PaymentStatus.PAID;
    final isOverdue = status == PaymentStatus.OVERDUE;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.shade50
            : isPaid
                ? Colors.green.shade50
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : isPaid
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _statusIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid
                      ? 'Paid on ${DateFormat('dd MMM yyyy').format(dueDate)}'
                      : 'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (!isPaid && onPayNow != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: onPayNow,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      backgroundColor: isOverdue
                          ? Colors.red.shade600
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Pay Now', style: TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    IconData icon;
    Color color;
    switch (status) {
      case PaymentStatus.PAID:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PaymentStatus.OVERDUE:
        icon = Icons.error;
        color = Colors.red;
        break;
      case PaymentStatus.PENDING:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }
    return Icon(icon, color: color, size: 28);
  }
}
