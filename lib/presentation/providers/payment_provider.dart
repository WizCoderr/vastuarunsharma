import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasources/remote/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/response/order_response.dart';
import '../../data/models/response/upi_payment_response.dart';
import 'course_provider.dart';

import '../../data/models/response/student_payment_model.dart';

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

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final remoteDataSource = ref.watch(paymentRemoteDataSourceProvider);
  return PaymentRepository(remoteDataSource);
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

  Future<PayuPaymentParams> createOrder(String courseId) async {
    if (courseId.trim().isEmpty) {
      throw Exception('courseId is required');
    }

    state = const AsyncValue.loading();
    debugPrint("PaymentController: creating PayU payment for $courseId");

    final result = await _repository.createOrder(courseId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        state = const AsyncValue.data(null);
        return order;
      },
    );
  }

  Future<PayuPaymentParams> createInstallmentOrder(String paymentId) async {
    if (paymentId.trim().isEmpty) {
      throw Exception('paymentId is required');
    }

    state = const AsyncValue.loading();
    final result = await _repository.createInstallmentOrder(paymentId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        state = const AsyncValue.data(null);
        return order;
      },
    );
  }

  Future<PayuPaymentParams> createRemediesPayuOrder(String orderId) async {
    if (orderId.trim().isEmpty) throw Exception('orderId is required');

    state = const AsyncValue.loading();
    final result = await _repository.createRemediesOrder(orderId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (order) {
        state = const AsyncValue.data(null);
        return order;
      },
    );
  }

  Future<String> generatePayuHash({
    required String txnid,
    required String hashName,
    String? hashString,
    String? hashType,
    String? postSalt,
  }) async {
    final result = await _repository.generatePayuHash(
      txnid: txnid,
      hashName: hashName,
      hashString: hashString,
      hashType: hashType,
      postSalt: postSalt,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (hash) => hash,
    );
  }

  Future<PayuStatusResponse> waitForPayuFulfillment(String txnid) async {
    state = const AsyncValue.loading();
    final result = await _repository.waitForPayuFulfillment(txnid);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (status) {
        state = const AsyncValue.data(null);
        return status;
      },
    );
  }

  Future<bool> freeEnroll(String courseId) async {
    if (courseId.trim().isEmpty) {
      throw Exception('courseId is required');
    }

    state = const AsyncValue.loading();
    final result = await _repository.freeEnroll(courseId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        throw Exception(failure.message);
      },
      (success) {
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
