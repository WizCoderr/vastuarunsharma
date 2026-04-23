import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../../data/models/response/student_payment_model.dart';
import '../../widgets/glass_container.dart';

class PaymentProgressScreen extends ConsumerWidget {
  final String courseId;
  const PaymentProgressScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(studentCoursePaymentsProvider(courseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Payment Progress"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text("No payments found for this course."));
          }

          final totalPaid = payments
              .where((p) => p.status == PaymentStatus.paid)
              .fold<double>(0, (sum, p) => sum + p.amount);
          final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
          final progress = totalAmount > 0 ? totalPaid / totalAmount : 0.0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Progress Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 16,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Overall Progress",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Paid: ₹${totalPaid.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        Text("Total: ₹${totalAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Payment History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),              ...payments.map((p) => _PaymentTile(payment: p)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final StudentPaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == PaymentStatus.paid;
    final isOverdue = payment.status == PaymentStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _statusIcon(payment.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  "Due: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}",
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${payment.amount.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (!isPaid)
                TextButton(
                  onPressed: () {
                    context.push('/payment/${payment.courseId}');
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text("Pay Now"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(PaymentStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case PaymentStatus.paid:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PaymentStatus.overdue:
        icon = Icons.error;
        color = Colors.red;
        break;
      case PaymentStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }
    return Icon(icon, color: color, size: 28);
  }
}
