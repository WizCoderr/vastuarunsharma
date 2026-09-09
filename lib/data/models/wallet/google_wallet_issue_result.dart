class GoogleWalletIssueResult {
  final String saveUrl;
  final String saveJwt;
  final String objectId;
  final String classId;
  final String status;

  GoogleWalletIssueResult({
    required this.saveUrl,
    required this.saveJwt,
    required this.objectId,
    required this.classId,
    required this.status,
  });

  factory GoogleWalletIssueResult.fromJson(Map<String, dynamic> json) {
    return GoogleWalletIssueResult(
      saveUrl: json['saveUrl'] as String? ?? '',
      saveJwt: json['saveJwt'] as String? ?? '',
      objectId: json['objectId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
