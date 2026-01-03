import '../../shared/utils/either.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/payment_remote_datasource.dart';
import '../models/response/order_response.dart';

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

  Future<Either<Failure, bool>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String courseId,
  }) async {
    try {
      final success = await remoteDataSource.verifyPayment(
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        courseId,
      );
      return Right(success);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
