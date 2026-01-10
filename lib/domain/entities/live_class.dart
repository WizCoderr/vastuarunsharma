class LiveClass {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // SCHEDULED | LIVE | COMPLETED
  final String? meetingUrl;
  final bool canJoin;
  final int startsIn;

  const LiveClass({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.meetingUrl,
    required this.canJoin,
    required this.startsIn,
  });
}
