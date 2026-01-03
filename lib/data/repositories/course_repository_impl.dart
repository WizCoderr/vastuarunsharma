import 'package:vastu_mobile/shared/utils/either.dart';
import '../../domain/entities/course.dart' as entity;
import '../../domain/repositories/course_repository.dart';
import '../datasources/remote/course_remote_datasource.dart';
import '../models/response/course_response.dart';
import '../../core/errors/failures.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remote;
  CourseRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<entity.Course>>> getAllCourses() async {
    try {
      final resp = await remote.fetchAllCourses();
      final list = resp.map((r) => _map(r)).toList();
      return Right(list);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.Course>>> getEnrolledCourses() async {
    try {
      final resp = await remote.fetchEnrolledCourses();
      final list = resp.map((r) => _map(r)).toList();
      return Right(list);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity.Course>> getCourseDetails(
    String courseId,
  ) async {
    try {
      final r = await remote.fetchCourseDetails(courseId);
      return Right(_map(r));
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getCourseCurriculum(String courseId) async {
    try {
      final curr = await remote.fetchCourseCurriculum(courseId);
      return Right(curr);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  entity.Course _map(CourseResponse r) => entity.Course(
    id: r.id,
    title: r.title,
    description: r.description,
    thumbnail: r.thumbnail,
    price: r.price,
    published: r.published,
    instructorId: r.instructorId,
    mediaType: r.mediaType ?? 'image',
    enrolled: r.enrolled,
    sections: r.sections.map((s) => _mapSection(s)).toList(),
    resources: r.resources.map((res) => _mapResource(res)).toList(),
  );

  entity.Section _mapSection(SectionResponse s) => entity.Section(
    id: s.id,
    title: s.title,
    lectures: s.lectures.map((l) => _mapLecture(l)).toList(),
  );

  entity.Lecture _mapLecture(LectureResponse l) => entity.Lecture(
    id: l.id,
    title: l.title,
    videoUrl: l.videoUrl,
    videoProvider: l.videoProvider,
  );

  entity.Resource _mapResource(ResourceResponse r) =>
      entity.Resource(id: r.id, title: r.title, type: r.type, url: r.url);
}
