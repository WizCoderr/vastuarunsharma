import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.description,
    required super.videoUrl,
    super.thumbnail,
    required super.date,
    required super.durationMinutes,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String? ?? '', // Handle strictly if needed
      title: json['title'] as String,
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] as String,
      thumbnail: json['thumbnail'] as String?,
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String) 
          : DateTime.now(), // Fallback or nullable
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }
}
