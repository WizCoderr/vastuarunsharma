class ProgressUpdateRequest {
  final String lectureId;
  final String courseId;
  final String status; // "completed" | "in-progress"
  final int watchedDuration;

  ProgressUpdateRequest({
    required this.lectureId,
    required this.courseId,
    required this.status,
    required this.watchedDuration,
  });

  Map<String, dynamic> toJson() => {
    'lectureId': lectureId,
    'courseId': courseId,
    'status': status,
    'watchedDuration': watchedDuration,
  };
}
