abstract class Either<L, R> {
  const Either();
  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  @override
  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) => onLeft(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  @override
  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) => onRight(value);
}
