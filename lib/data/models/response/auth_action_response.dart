class AuthActionResponse {
  const AuthActionResponse({required this.success, required this.message});

  final bool success;
  final String message;

  factory AuthActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final nestedMessage = data is Map<String, dynamic> ? data['message'] : null;
    final topLevelMessage = json['message'];

    return AuthActionResponse(
      success: json['success'] == true,
      message:
          (nestedMessage ?? topLevelMessage ?? 'Request completed successfully')
              .toString(),
    );
  }
}
