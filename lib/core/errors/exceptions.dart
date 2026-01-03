class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class AuthException extends AppException {
  AuthException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class StorageException extends AppException {
  StorageException(super.message);
}

class ServerException extends AppException {
  final int? statusCode;
  ServerException(super.message, [this.statusCode]);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}
