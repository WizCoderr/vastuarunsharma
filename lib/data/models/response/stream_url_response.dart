class StreamUrlResponse {
  final String lectureId;
  final String url;
  final String? cdnProvider;

  StreamUrlResponse({
    required this.lectureId,
    required this.url,
    this.cdnProvider,
  });

  factory StreamUrlResponse.fromJson(Map<String, dynamic> json) =>
      StreamUrlResponse(
        lectureId: json['lectureId'] as String? ?? '',
        url: json['url'] as String? ?? '',
        cdnProvider: json['cdnProvider'] as String?,
      );
}
