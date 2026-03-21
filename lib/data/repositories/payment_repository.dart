import '../../shared/utils/either.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/payment_remote_datasource.dart';
import '../models/response/order_response.dart';
import '../models/course_model.dart';
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

  Future<Either<Failure, List<PaymentPlanModel>>> getPaymentPlan(
    String courseId,
  ) async {
    try {
      final plan = await remoteDataSource.getPaymentPlan(courseId);
      return Right(plan);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, OrderResponse>> enrollInCourse(String courseId) async {
    try {
      final order = await remoteDataSource.enrollInCourse(courseId);
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

  Future<Either<Failure, OrderResponse>> payInstallment(
    String paymentId,
  ) async {
    try {
      final order = await remoteDataSource.payInstallment(paymentId);
      return Right(order);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String courseId,
    String? paymentId,
  }) async {
    try {
      final success = await remoteDataSource.verifyPayment(
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        courseId,
        paymentId: paymentId,
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
