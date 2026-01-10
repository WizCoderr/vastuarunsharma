import '../../domain/entities/live_class.dart';

class LiveClassModel extends LiveClass {
  const LiveClassModel({
    required super.id,
    required super.courseId,
    required super.courseName,
    required super.title,
    required super.description,
    required super.scheduledAt,
    required super.durationMinutes,
    required super.status,
    super.meetingUrl,
    required super.canJoin,
    required super.startsIn,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    return LiveClassModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      status: json['status'] as String,
      meetingUrl: json['meetingUrl'] as String?,
      canJoin: json['canJoin'] as bool? ?? false,
      startsIn: json['startsIn'] as int? ?? 0,
    );
  }
}
