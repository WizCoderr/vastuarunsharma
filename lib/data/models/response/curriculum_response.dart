class LectureResponse {
  final String id;
  final String title;
  final int durationSeconds;

  LectureResponse({
    required this.id,
    required this.title,
    required this.durationSeconds,
  });

  factory LectureResponse.fromJson(Map<String, dynamic> json) =>
      LectureResponse(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );
}

class SectionResponse {
  final String id;
  final String title;
  final List<LectureResponse> lectures;

  SectionResponse({
    required this.id,
    required this.title,
    required this.lectures,
  });

  factory SectionResponse.fromJson(Map<String, dynamic> json) =>
      SectionResponse(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        lectures:
            (json['lectures'] as List<dynamic>?)
                ?.map(
                  (e) => LectureResponse.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class CurriculumResponse {
  final String courseId;
  final double progress;
  final List<SectionResponse> sections;

  CurriculumResponse({
    required this.courseId,
    required this.progress,
    required this.sections,
  });

  factory CurriculumResponse.fromJson(Map<String, dynamic> json) =>
      CurriculumResponse(
        courseId: json['courseId'] as String? ?? '',
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        sections:
            (json['sections'] as List<dynamic>?)
                ?.map(
                  (e) => SectionResponse.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
