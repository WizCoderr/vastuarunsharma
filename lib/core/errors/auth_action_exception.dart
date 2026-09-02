class AuthActionException implements Exception {
  const AuthActionException(this.message, {this.isInvalidToken = false});

  final String message;
  final bool isInvalidToken;

  @override
  String toString() => message;
}
