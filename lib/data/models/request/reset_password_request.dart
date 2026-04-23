class ResetPasswordRequest {
  const ResetPasswordRequest({required this.token, required this.password});

  final String token;
  final String password;

  Map<String, dynamic> toJson() {
    return {'token': token.trim(), 'password': password};
  }
}
