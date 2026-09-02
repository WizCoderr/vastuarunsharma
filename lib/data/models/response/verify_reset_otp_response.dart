class VerifyResetOtpResponse {
  const VerifyResetOtpResponse({
    required this.success,
    required this.message,
    required this.resetToken,
  });

  final bool success;
  final String message;
  final String resetToken;

  factory VerifyResetOtpResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final nestedMessage = data is Map<String, dynamic> ? data['message'] : null;
    final nestedResetToken =
        data is Map<String, dynamic> ? data['resetToken'] : null;

    return VerifyResetOtpResponse(
      success: json['success'] == true,
      message: (nestedMessage ?? json['message'] ?? 'Code verified')
          .toString(),
      resetToken: (nestedResetToken ?? '').toString(),
    );
  }
}
