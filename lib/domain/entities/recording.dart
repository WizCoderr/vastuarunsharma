class Recording {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnail;
  final DateTime date;
  final int durationMinutes;

  const Recording({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnail,
    required this.date,
    required this.durationMinutes,
  });
}
