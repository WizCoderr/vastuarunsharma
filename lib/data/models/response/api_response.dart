class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    final dataJson = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: dataJson == null ? null : fromJsonT(dataJson),
    );
  }
}
