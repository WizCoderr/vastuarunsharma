class AuthActionResponse {
  const AuthActionResponse({required this.success, required this.message, this.devOtp});

  final bool success;
  final String message;
  final String? devOtp;

  factory AuthActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final nestedMessage = data is Map<String, dynamic> ? data['message'] : null;
    final devOtp = data is Map<String, dynamic> ? data['devOtp'] as String? : null;
    final topLevelMessage = json['message'];

    return AuthActionResponse(
      success: json['success'] == true,
      message:
          (nestedMessage ?? topLevelMessage ?? 'Request completed successfully')
              .toString(),
      devOtp: devOtp,
    );
  }
}
