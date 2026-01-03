import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasources/remote/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository.dart';
import 'course_provider.dart';

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

// Payment Controller / Notifier
class PaymentController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentController(this._repository) : super(const AsyncValue.data(null));

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
        // Surface the error to the caller so the UI can show exact server response
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

  Future<bool> verifyPayment({
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
        // Surface the error to the caller so the UI can show exact server response
        throw Exception(failure.message);
      },
      (success) {
        debugPrint("PaymentController: verifyPayment success");
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
