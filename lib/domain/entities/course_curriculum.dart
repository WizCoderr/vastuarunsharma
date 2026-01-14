import 'course.dart';
import 'live_class.dart';

class CourseCurriculum {
  final String courseId;
  final double progress; // 0.0 to 1.0 (percent / 100)
  final List<Section> sections;
  final List<LiveClass> liveClasses;

  CourseCurriculum({
    required this.courseId,
    required this.progress,
    required this.sections,
    required this.liveClasses,
  });
}
