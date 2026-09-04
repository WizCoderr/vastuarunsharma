import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasources/remote/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/response/upi_payment_response.dart';
import 'course_provider.dart';

import '../../data/models/response/student_payment_model.dart';

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

// Payment Controller / Notifier
class PaymentController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentController(this._repository) : super(const AsyncValue.data(null));

  Future<UpiPaymentResponse> createRemediesUpiPayment(String orderId) async {
    if (orderId.trim().isEmpty) throw Exception('orderId is required');

    state = const AsyncValue.loading();
    final result = await _repository.createRemediesUpiPayment(orderId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (payment) {
        state = const AsyncValue.data(null);
        return payment;
      },
    );
  }

  Future<UpiPaymentResponse> createCourseUpiPayment(String courseId) async {
    if (courseId.trim().isEmpty) throw Exception('courseId is required');

    state = const AsyncValue.loading();
    final result = await _repository.createCourseUpiPayment(courseId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (payment) {
        state = const AsyncValue.data(null);
        return payment;
      },
    );
  }

  Future<PaymentStatusResponse> getPaymentStatus(String transactionId) async {
    final result = await _repository.getPaymentStatus(transactionId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (status) => status,
    );
  }

  Future<void> verifyUpiPayment(String transactionId) async {
    final result = await _repository.verifyUpiPayment(transactionId);
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => null,
    );
  }

  Future<Map<String, dynamic>?> createOrder(String courseId) async {
    if (courseId.trim().isEmpty) {
      debugPrint('PaymentController: createOrder called with empty courseId');
      throw Exception('courseId is required');
    }

    state = const AsyncValue.loading();
    debugPrint("PaymentController: creating order for $courseId");

    final result = await _repository.createOrder(courseId);

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
          'description': 'Course Purchase',
        };
      },
    );
  }

  Future<String?> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String courseId,
  }) async {
    if (razorpayOrderId.trim().isEmpty ||
        razorpayPaymentId.trim().isEmpty ||
        razorpaySignature.trim().isEmpty ||
        courseId.trim().isEmpty) {
      debugPrint(
        'PaymentController: verifyPayment called with incomplete details -> order:$razorpayOrderId payment:$razorpayPaymentId signature:$razorpaySignature course:$courseId',
      );
      throw Exception('Incomplete payment details');
    }

    state = const AsyncValue.loading();
    debugPrint(
      "PaymentController: verifying payment $razorpayPaymentId for course $courseId",
    );

    final result = await _repository.verifyPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      courseId: courseId,
    );

    return result.fold(
      (failure) {
        debugPrint(
          "PaymentController: verifyPayment failed: ${failure.message}",
        );
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (serialNumber) {
        debugPrint("PaymentController: verifyPayment success, serial: $serialNumber");
        state = const AsyncValue.data(null);
        return serialNumber;
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
