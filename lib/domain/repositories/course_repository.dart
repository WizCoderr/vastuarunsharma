import 'package:vastuarunsharma/shared/utils/either.dart';
import '../entities/course.dart';
import '../entities/course_curriculum.dart';
import '../../core/errors/failures.dart';

abstract class CourseRepository {
  Future<Either<Failure, List<Course>>> getAllCourses();
  Future<Either<Failure, List<Course>>> getEnrolledCourses();
  Future<Either<Failure, Course>> getCourseDetails(String courseId);
  Future<Either<Failure, CourseCurriculum>> getCourseCurriculum(
    String courseId,
  );
}
