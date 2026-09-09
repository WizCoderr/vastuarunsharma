import '../../shared/utils/either.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/payment_remote_datasource.dart';
import '../models/response/order_response.dart';
import '../models/response/student_payment_model.dart';
import '../models/response/upi_payment_response.dart';

class PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepository(this.remoteDataSource);

  Future<Either<Failure, PayuPaymentParams>> createOrder(String courseId) async {
    try {
      final order = await remoteDataSource.createOrder(courseId);
      return Right(order);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, PayuPaymentParams>> createInstallmentOrder(
    String paymentId,
  ) async {
    try {
      final order = await remoteDataSource.createInstallmentOrder(paymentId);
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

  Future<Either<Failure, PayuPaymentParams>> createRemediesOrder(
    String orderId,
  ) async {
    try {
      final order = await remoteDataSource.createRemediesOrder(orderId);
      return Right(order);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> generatePayuHash({
    required String txnid,
    required String hashName,
    String? hashString,
    String? hashType,
    String? postSalt,
  }) async {
    try {
      final hash = await remoteDataSource.generatePayuHash(
        txnid: txnid,
        hashName: hashName,
        hashString: hashString,
        hashType: hashType,
        postSalt: postSalt,
      );
      return Right(hash);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, PayuStatusResponse>> getPayuStatus(String txnid) async {
    try {
      final status = await remoteDataSource.getPayuStatus(txnid);
      return Right(status);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, PayuStatusResponse>> waitForPayuFulfillment(
    String txnid,
  ) async {
    try {
      final status = await remoteDataSource.waitForPayuFulfillment(txnid);
      return Right(status);
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

  Future<Either<Failure, UpiPaymentResponse>> createRemediesUpiPayment(
    String orderId,
  ) async {
    try {
      final payment = await remoteDataSource.createRemediesUpiPayment(orderId);
      return Right(payment);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, UpiPaymentResponse>> createCourseUpiPayment(
    String courseId,
  ) async {
    try {
      final payment = await remoteDataSource.createCourseUpiPayment(courseId);
      return Right(payment);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, PaymentStatusResponse>> getPaymentStatus(
    String transactionId,
  ) async {
    try {
      final status = await remoteDataSource.getPaymentStatus(transactionId);
      return Right(status);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> verifyUpiPayment(String transactionId) async {
    try {
      await remoteDataSource.verifyUpiPayment(transactionId);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
