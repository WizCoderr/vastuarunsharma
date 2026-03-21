import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/payment_plan_card.dart';

class MyInstallmentsScreen extends ConsumerWidget {
  final String courseId;
  const MyInstallmentsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider(courseId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Installments'),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No installments found.'));
          }
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentPlanCard(
                stageName: payment.title,
                amount: payment.amount,
                dueDate: payment.dueDate,
                status: payment.status,
                onPayNow: () {
                  context.push(
                    RouteConstants.checkoutPath,
                    extra: {'courseId': courseId, 'paymentId': payment.id},
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

