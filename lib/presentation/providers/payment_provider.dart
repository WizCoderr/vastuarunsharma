import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasources/remote/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository.dart';
import 'course_provider.dart';

import '../../data/models/response/student_payment_model.dart';
import '../../domain/entities/course.dart';

// Remote DataSource Provider
final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((
  ref,
) {
  final dioClientAsync = ref.watch(dioClientProvider);

  return dioClientAsync.when(
    data: (dioClient) => PaymentRemoteDataSource(dioClient),
    loading: () => throw Exception("DioClient is initializing..."),
    error: (err, stack) =>
        throw Exception("DioClient failed to initialize: $err"),
  );
});

// Repository Provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final remoteDataSource = ref.watch(paymentRemoteDataSourceProvider);
  return PaymentRepository(remoteDataSource);
});

// Providers for fetching data
final coursePaymentPlanProvider =
    FutureProvider.family<List<PaymentPlan>, String>((ref, courseId) async {
      final repository = ref.watch(paymentRepositoryProvider);
      final result = await repository.getPaymentPlan(courseId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (plan) => plan,
      );
    });

final studentCoursePaymentsProvider =
    FutureProvider.family<List<StudentPaymentModel>, String>((
      ref,
      courseId,
    ) async {
      final repository = ref.watch(paymentRepositoryProvider);
      final result = await repository.getStudentCoursePayments(courseId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (payments) => payments,
      );
    });

final myPaymentsProvider =
    FutureProvider.family<List<StudentPaymentModel>, String>((ref, courseId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final result = await repository.getStudentCoursePayments(courseId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (payments) => payments,
  );
});

// Payment Controller / Notifier
class PaymentController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentController(this._repository) : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>?> createRemediesOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      debugPrint(
          'PaymentController: createRemediesOrder called with empty orderId');
      throw Exception('orderId is required');
    }

    state = const AsyncValue.loading();
    debugPrint("PaymentController: creating order for remedy $orderId");

    final result = await _repository.createRemediesOrder(orderId);

    return result.fold(
      (failure) {
        debugPrint(
            "PaymentController: createRemediesOrder failed: ${failure.message}");
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        debugPrint(
            "PaymentController: createRemediesOrder success: ${order.id}");
        state = const AsyncValue.data(null);
        return {
          'id': order.id,
          'amount': order.amount,
          'currency': order.currency,
          'key': order.key,
          'description': 'Remedy Purchase',
        };
      },
    );
  }

  Future<bool> verifyRemediesPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    if (razorpayOrderId.trim().isEmpty ||
        razorpayPaymentId.trim().isEmpty ||
        razorpaySignature.trim().isEmpty ||
        orderId.trim().isEmpty) {
      debugPrint(
        'PaymentController: verifyRemediesPayment called with incomplete details -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature orderId:$orderId',
      );
      throw Exception('Incomplete payment details');
    }

    state = const AsyncValue.loading();
    debugPrint(
      "PaymentController: verifying payment $razorpayPaymentId for remedy order $orderId",
    );

    final result = await _repository.verifyRemediesPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      orderId: orderId,
    );

    return result.fold(
      (failure) {
        debugPrint(
          "PaymentController: verifyRemediesPayment failed: ${failure.message}",
        );
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (success) {
        debugPrint("PaymentController: verifyRemediesPayment success");
        state = const AsyncValue.data(null);
        return success;
      },
    );
  }

  Future<Map<String, dynamic>?> createOrder(
    String courseId, {
    String? paymentId,
  }) async {
    if (courseId.trim().isEmpty && paymentId == null) {
      debugPrint('PaymentController: createOrder called with empty identifiers');
      throw Exception('courseId or paymentId is required');
    }

    state = const AsyncValue.loading();
    debugPrint("PaymentController: creating order for $courseId / $paymentId");

    final result =
        paymentId != null
            ? await _repository.payInstallment(paymentId)
            : await _repository.createOrder(courseId);

    return result.fold(
      (failure) {
        debugPrint("PaymentController: createOrder failed: ${failure.message}");
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        debugPrint("PaymentController: createOrder success: ${order.id}");
        state = const AsyncValue.data(null);
        return {
          'id': order.id,
          'amount': order.amount,
          'currency': order.currency,
          'key': order.key,
          'description': paymentId != null ? 'Installment Payment' : 'Course Purchase',
        };
      },
    );
  }

  Future<Map<String, dynamic>?> enrollInCourse(String courseId) async {
    state = const AsyncValue.loading();
    final result = await _repository.enrollInCourse(courseId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        state = const AsyncValue.data(null);
        return {
          'id': order.id,
          'amount': order.amount,
          'currency': order.currency,
          'key': order.key,
          'description': 'Course Enrollment (Staged)',
        };
      },
    );
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String courseId,
    String? paymentId,
  }) async {
    if (razorpayOrderId.trim().isEmpty ||
        razorpayPaymentId.trim().isEmpty ||
        razorpaySignature.trim().isEmpty ||
        (courseId.trim().isEmpty && paymentId == null)) {
      debugPrint(
        'PaymentController: verifyPayment called with incomplete details -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature course:$courseId paymentId:$paymentId',
      );
      throw Exception('Incomplete payment details');
    }

    state = const AsyncValue.loading();
    debugPrint(
      "PaymentController: verifying payment $razorpayPaymentId for course $courseId / $paymentId",
    );

    final result = await _repository.verifyPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      courseId: courseId,
      paymentId: paymentId,
    );

    return result.fold(
      (failure) {
        debugPrint(
          "PaymentController: verifyPayment failed: ${failure.message}",
        );
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (success) {
        debugPrint("PaymentController: verifyPayment success");
        state = const AsyncValue.data(null);
        return success;
      },
    );
  }

  Future<bool> freeEnroll(String courseId) async {
    if (courseId.trim().isEmpty) {
      debugPrint('PaymentController: freeEnroll called with empty courseId');
      throw Exception('courseId is required');
    }

    state = const AsyncValue.loading();
    debugPrint("PaymentController: processing free enrollment for $courseId");

    final result = await _repository.freeEnroll(courseId);

    return result.fold(
      (failure) {
        debugPrint(
          "PaymentController: freeEnroll failed: ${failure.message}",
        );
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (success) {
        debugPrint("PaymentController: freeEnroll success");
        state = const AsyncValue.data(null);
        return success;
      },
    );
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
      final repository = ref.watch(paymentRepositoryProvider);
      return PaymentController(repository);
    });
