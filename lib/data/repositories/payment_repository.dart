import '../../shared/utils/either.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/payment_remote_datasource.dart';
import '../models/response/order_response.dart';
import '../models/response/student_payment_model.dart';

class PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepository(this.remoteDataSource);

  Future<Either<Failure, OrderResponse>> createOrder(String courseId) async {
    try {
      final order = await remoteDataSource.createOrder(courseId);
      return Right(order);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<StudentPaymentModel>>> getStudentCoursePayments(
    String courseId,
  ) async {
    try {
      final payments = await remoteDataSource.getStudentCoursePayments(courseId);
      return Right(payments);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, String?>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String courseId,
  }) async {
    try {
      final serialNumber = await remoteDataSource.verifyPayment(
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        courseId: courseId,
      );
      return Right(serialNumber);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, OrderResponse>> createRemediesOrder(
    String orderId,
  ) async {
    try {
      final order = await remoteDataSource.createRemediesOrder(orderId);
      return Right(order);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> verifyRemediesPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      final success = await remoteDataSource.verifyRemediesPayment(
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        orderId,
      );
      return Right(success);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> freeEnroll(String courseId) async {
    try {
      final success = await remoteDataSource.freeEnroll(courseId);
      return Right(success);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
